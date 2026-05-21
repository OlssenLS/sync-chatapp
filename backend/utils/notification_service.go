package utils

import (
	"context"
	"log"
	"os"
	"path/filepath"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type NotificationService struct {
	App *firebase.App
}

var GlobalNotificationService *NotificationService

func InitNotificationService() {
	ctx := context.Background()

	// Dynamically find the firebase key file in the backend directory
	var keyFile string
	files, err := os.ReadDir(".")
	if err == nil {
		for _, file := range files {
			if !file.IsDir() && filepath.Ext(file.Name()) == ".json" &&
				(len(file.Name()) > 8 && file.Name()[:8] == "sync-mob") {
				keyFile = file.Name()
				break
			}
		}
	}

	if keyFile == "" {
		log.Println("Firebase key file not found. Push notifications will be disabled.")
		return
	}

	opt := option.WithCredentialsFile(keyFile)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("error initializing firebase app: %v\n", err)
		return
	}

	GlobalNotificationService = &NotificationService{App: app}
	log.Printf("Notification service initialized with key: %s\n", keyFile)
}

func (s *NotificationService) SendPushNotification(token string, title, body string, data map[string]string) {
	if s.App == nil || token == "" {
		return
	}

	ctx := context.Background()
	client, err := s.App.Messaging(ctx)
	if err != nil {
		log.Printf("error getting Messaging client: %v\n", err)
		return
	}

	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data:  data,
		Token: token,
	}

	response, err := client.Send(ctx, message)
	if err != nil {
		log.Printf("error sending message to %s: %v\n", token, err)
		return
	}
	log.Printf("Successfully sent message: %s\n", response)
}
