package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os/exec"
	"strings"

	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
)

func command_helm_install(logger *zap.Logger, ctx *cli.Context) error {
	domain := ctx.String("domain")
	baseUrl := fmt.Sprintf("https://api.%s", domain)
	gateway := fmt.Sprintf("gw.%s", domain)
	mediatorToken := ctx.String("token")
	clusterName := ctx.String("cluster-name")
	version := ctx.String("causely-version")

	if mediatorToken == "" {
		tokenResponse, err := getDefaultToken(baseUrl, logger, ctx.String("mediator"))
		if err != nil {
			logger.Error(err.Error())
			return err
		}

		type tokenResp struct {
			TokenValue string `json:"tokenValue"`
		}
		var tok tokenResp
		if err := json.Unmarshal(tokenResponse, &tok); err != nil {
			return fmt.Errorf("failed to parse token response: %w", err)
		}
		if tok.TokenValue == "" {
			return fmt.Errorf("mediator token was empty; only organization administrators can install without --token. Pass --token with your mediator secret, or ask an administrator to install")
		}
		mediatorToken = tok.TokenValue
	}

	set := "--set"
	command := []string{
		"helm", "upgrade", "--install", "causely", "--create-namespace",
	}

	if ctx.String("tag") != "" {
		version = ctx.String("tag")
	}

	if ctx.String("repository") != "" {
		helm := "oci://" + ctx.String("repository") + "/causely"
		command = append(command, helm, "--version", version)
		repository := "image.repository=" + ctx.String("repository")
		command = append(command, set, repository)
	}

	if ctx.String("namespace") != "" {
		namespace := "--namespace=" + ctx.String("namespace")
		command = append(command, namespace)
	}

	if ctx.String("tag") != "" {
		tag := "image.tag=" + ctx.String("tag")
		command = append(command, set, tag)
	}

	command = append(command, set, "mediator.gateway.host="+gateway)

	command = append(command, set, "mediator.gateway.token="+mediatorToken)

	if ctx.String("cluster-name") != "" {
		command = append(command, set, "global.cluster_name="+clusterName)
	} else {
		stdout, err := command_kubectx(logger)
		if err != nil {
			return err
		} else {
			command = append(command, set, "global.cluster_name="+stdout)
		}
	}

	if ctx.String("values") != "" {
		command = append(command, "--values", ctx.String("values"))
	}

	if ctx.String("kube-context") != "" {
		command = append(command, "--kube-context", ctx.String("kube-context"))
	}

	commands := [][]string{}
	commands = append(commands, command)
	logger.Info(fmt.Sprintf("command: %s %s", command[0], strings.Join(command[1:], " ")))
	if ctx.Bool("dry-run") {
		return nil
	}
	return execute_commands(logger, commands)
}

func command_helm_uninstall(logger *zap.Logger, ctx *cli.Context) error {

	command := []string{
		"helm", "uninstall", "-n", "causely", "causely",
	}

	if ctx.String("namespace") != "" {
		namespace := "--namespace=" + ctx.String("namespace")
		command = append(command, namespace)
	}

	if ctx.String("kube-context") != "" {
		command = append(command, "--kube-context", ctx.String("kube-context"))
	}

	commands := [][]string{}
	commands = append(commands, command)
	logger.Info(fmt.Sprintf("command: %s %s", command[0], strings.Join(command[1:], " ")))
	if ctx.Bool("dry-run") {
		return nil
	}
	return execute_commands(logger, commands)
}

func command_kubectx(logger *zap.Logger) (string, error) {
	var cmdout string

	cmd := exec.Command("kubectx", "--current")

	// Get the stderr pipe
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return "", fmt.Errorf("failed to get stderr pipe: %v", err)
	}

	// Get the stdout pipe
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return "", fmt.Errorf("failed to get stdout pipe: %v", err)
	}

	// Start the command
	if err = cmd.Start(); err != nil {
		logger.Warn("kubectx not found, trying kubectl ctx plugin")
		// Redefine the command
		cmd = exec.Command("kubectl", "ctx", "--current")

		// Get the stderr pipe
		stderr, err = cmd.StderrPipe()
		if err != nil {
			return "", fmt.Errorf("failed to get stderr pipe: %v", err)
		}

		// Get the stdout pipe
		stdout, err = cmd.StdoutPipe()
		if err != nil {
			return "", fmt.Errorf("failed to get stdout pipe: %v", err)
		}

		if err = cmd.Start(); err != nil {
			logger.Warn("kubectl ctx plugin not found, specify the cluster name with --cluster-name <mycluster>")
			return "", fmt.Errorf("%s", err)
		}
	}

	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			cmderr := scanner.Text()
			logger.Warn(cmderr)
		}
	}()

	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			cmdout = scanner.Text()
		}
	}()

	// Wait for the command to finish
	if err = cmd.Wait(); err != nil {
		// Collect stderr output if the command fails
		logger.Warn("kubectl ctx plugin not found, specify the cluster name with --cluster-name <mycluster>")
		return cmdout, fmt.Errorf("command failed: %v", err)
	}

	return cmdout, nil
}

func execute_commands(logger *zap.Logger, commands [][]string) error {
	for _, cmd := range commands {
		err := run_command(logger, cmd[0], cmd[1:])
		if err != nil {
			return err
		}
	}
	return nil
}

func run_command(logger *zap.Logger, command string, args []string) error {
	cmd := exec.Command(command, args...)

	stderr, err := cmd.StderrPipe()

	if err != nil {
		return err
	}

	stdout, err := cmd.StdoutPipe()

	if err != nil {
		return err
	}

	err = cmd.Start()

	if err != nil {
		return err
	}

	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			m := scanner.Text()
			fmt.Println(m)
		}
	}()

	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			m := scanner.Text()
			fmt.Println(m)
		}
	}()

	return cmd.Wait()
}

func getDefaultToken(baseUrl string, logger *zap.Logger, mediator string) ([]byte, error) {
	tok, err := loadToken(logger)
	if err != nil {
		return nil, err
	}
	reqURL := baseUrl + "/api/tokens/default"
	if m := strings.TrimSpace(mediator); m != "" {
		reqURL = reqURL + "?mediator=" + url.QueryEscape(m)
	}
	client := &http.Client{}
	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("authorization", "Bearer "+tok.AccessToken)

	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err := res.Body.Close(); err != nil {
			logger.Error("Failed to close response body", zap.Error(err))
		}
	}()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	if res.StatusCode != http.StatusOK {
		var apiErr struct {
			Error string `json:"error"`
		}
		_ = json.Unmarshal(body, &apiErr)
		detail := strings.TrimSpace(apiErr.Error)
		if detail == "" {
			detail = strings.TrimSpace(string(body))
		}
		if detail == "" {
			detail = res.Status
		}
		if res.StatusCode == http.StatusUnauthorized {
			return nil, fmt.Errorf("authentication failed (%s): log in again with \"causely auth login\"", detail)
		}
		if res.StatusCode == http.StatusForbidden {
			return nil, fmt.Errorf("cannot fetch default mediator token: %s", detail)
		}
		if res.StatusCode == http.StatusNotFound {
			return nil, fmt.Errorf("mediator not found: %s", detail)
		}
		return nil, fmt.Errorf("request failed (%s): %s", res.Status, detail)
	}
	return body, nil
}
