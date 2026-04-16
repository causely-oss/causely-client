package main

import (
	"fmt"
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"github.com/urfave/cli/v2"
)

var version = "dev"

func main() {
	encoderConfig := zap.NewDevelopmentEncoderConfig()
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	encoder := zapcore.NewConsoleEncoder(encoderConfig)
	core := zapcore.NewCore(encoder, zapcore.AddSync(os.Stdout), zapcore.InfoLevel)
	logger := zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))

	defer func() {
		_ = logger.Sync()
	}()

	app := &cli.App{
		Name:  "causely",
		Usage: "causely auth|agent",
		Commands: []*cli.Command{{
			Name:  "version",
			Usage: "version",
			Action: func(ctx *cli.Context) error {
				fmt.Println(version)
				return nil
			},
		}, {
			Name:  "auth",
			Usage: "auth login --user name [--password secret]",
			Subcommands: []*cli.Command{{
				Name:  "login",
				Usage: "login --user name [--password secret]",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "url",
						Value: "https://app-u79khqcmarmf.frontegg.com",
					},
					&cli.StringFlag{
						Name: "user",
					},
					&cli.StringFlag{
						Name: "password",
					},
				},
				Action: func(ctx *cli.Context) error {
					return command_login(logger, ctx)
				},
			}},
		}, {
			Name:  "agent",
			Usage: "agent install|uninstall",
			Subcommands: []*cli.Command{{
				Name:  "install",
				Usage: "install --namespace my_namespace --repository my_repo/org --tag version --gateway address --mediator my_cluster --cluster-name my-cluster --values my_values.yaml --kube-context my_ctx",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "domain",
						Value: "causely.app",
					},
					&cli.StringFlag{
						Name:  "namespace",
						Value: "causely",
					},
					&cli.StringFlag{
						Name:  "repository",
						Value: "us-docker.pkg.dev/public-causely/public",
					},
					&cli.StringFlag{
						Name:  "tag",
						Value: version,
					},
					&cli.StringFlag{
						Name: "cluster-name",
					},
					&cli.StringFlag{
						Name: "token",
					},
					&cli.StringFlag{
						Name: "mediator",
					},
					&cli.StringFlag{
						Name: "values",
					},
					&cli.StringFlag{
						Name: "kube-context",
					},
					&cli.BoolFlag{
						Name:  "dry-run",
						Value: false,
					},
				},
				Action: func(ctx *cli.Context) error {
					return command_helm_install(logger, ctx)
				},
			}, {
				Name:  "uninstall",
				Usage: "uninstall --namespace my_namespace --kube-context my_ctx",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "namespace",
						Value: "causely",
					},
					&cli.StringFlag{
						Name: "kube-context",
					},
				},
				Action: func(ctx *cli.Context) error {
					return command_helm_uninstall(logger, ctx)
				},
			}},
		},
		}}

	if err := app.Run(os.Args); err != nil {
		logger.Warn("failed: ", zap.Error(err))
	}
}
