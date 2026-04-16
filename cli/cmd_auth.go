package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
	"golang.org/x/term"
)

const (
	causelyDotPath  = ".causely"
	causelyAuthFile = "auth.json"
)

type UserResponse struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	ExpiresIn    int    `json:"expiresIn"`
}

func command_login(logger *zap.Logger, ctx *cli.Context) error {
	url := ctx.String("url")
	loginUrl := fmt.Sprintf("%s/identity/resources/auth/v1/user", url)

	userName := ctx.String("user")
	if userName == "" {
		fmt.Print("\nEnter username: ")
		reader := bufio.NewReader(os.Stdin)
		usr, err := reader.ReadString('\n')
		if err != nil {
			return err
		}
		userName = strings.TrimSuffix(usr, "\n")
	}
	password := ctx.String("password")
	if password == "" {
		fmt.Print("\nEnter password (won't echo): ")
		pass, err := term.ReadPassword(syscall.Stdin)
		fmt.Print("\n")
		if err != nil {
			return err
		}
		password = string(pass)
	}

	payload := strings.NewReader("{\"email\": \"" + userName + "\", \"password\": \"" + password + "\"}")

	client := &http.Client{}
	req, err := http.NewRequest(http.MethodPost, loginUrl, payload)

	if err != nil {
		logger.Error(err.Error())
		return err
	}
	req.Header.Add("accept", "application/json")
	req.Header.Add("Content-Type", "application/json")

	res, err := client.Do(req)
	if err != nil {
		logger.Error(err.Error())
		return err
	}
	defer func() {
		if err := res.Body.Close(); err != nil {
			logger.Error("Failed to close response body", zap.Error(err))
		}
	}()

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("request returned a non-OK status: %s", res.Status)
	}

	responseData, err := io.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("error reading response body: %w", err)
	}

	var response UserResponse
	if err = json.Unmarshal(responseData, &response); err != nil {
		return err
	}

	err = saveToken(response, logger)
	if err != nil {
		return err
	}
	return nil
}

// ensureDotFolderPath returns and creates the dot folder for cli auth.
func ensureDotFolderPath() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	causelyDirPath := filepath.Join(home, causelyDotPath)
	if _, err := os.Stat(causelyDirPath); os.IsNotExist(err) {
		err = os.Mkdir(causelyDirPath, 0744)
		if err != nil {
			return "", err
		}
	}

	return causelyDirPath, nil
}

// ensureDefaultAuthFilePath returns the file path for the auth file.
func ensureDefaultAuthFilePath() (string, error) {
	causelyDirPath, err := ensureDotFolderPath()
	if err != nil {
		return "", err
	}

	causelyAuthFilePath := filepath.Join(causelyDirPath, causelyAuthFile)
	return causelyAuthFilePath, nil
}

// saveToken saves the refresh token in default spot.
func saveToken(token UserResponse, logger *zap.Logger) error {
	causelyAuthFilePath, err := ensureDefaultAuthFilePath()
	if err != nil {
		return err
	}

	f, err := os.OpenFile(causelyAuthFilePath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		return err
	}
	defer func() {
		if err := f.Close(); err != nil {
			logger.Error("Failed to close auth file", zap.Error(err))
		}
	}()

	return json.NewEncoder(f).Encode(token)
}

// loadToken loads the token for the user.
func loadToken(logger *zap.Logger) (UserResponse, error) {
	var token UserResponse
	causelyAuthFilePath, err := ensureDefaultAuthFilePath()
	if err != nil {
		return token, err
	}
	f, err := os.Open(causelyAuthFilePath)
	if err != nil {
		return token, err
	}
	defer func() {
		if err := f.Close(); err != nil {
			logger.Error("Failed to close auth file", zap.Error(err))
		}
	}()

	if err := json.NewDecoder(f).Decode(&token); err != nil {
		return token, err
	}

	return token, nil
}
