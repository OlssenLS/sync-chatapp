package db

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

var Client *mongo.Client

func ConnectDB() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// In a real app, use environment variables for the URI
	uri := "mongodb://127.0.0.1:27017"
	client, err := mongo.Connect(options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB:", err)
	}

	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatal("Failed to ping MongoDB:", err)
	}

	Client = client
	log.Println("Successfully connected to MongoDB")
}

func GetCollection(collectionName string) *mongo.Collection {
	return Client.Database("sync_chatapp").Collection(collectionName)
}
