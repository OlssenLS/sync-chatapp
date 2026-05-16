package db

import (
	"context"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

var Client *mongo.Client

func ConnectDB() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	uri := os.Getenv("MONGODB_URI")
	if uri == "" {
		log.Println("MONGODB_URI not set, falling back to local instance")
		uri = "mongodb://127.0.0.1:27017"
	}

	client, err := mongo.Connect(options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatalf("Failed to create MongoDB client: %v", err)
	}

	// Double check connection with a ping
	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatalf("Failed to ping MongoDB after 30s: %v", err)
	}

	Client = client
	log.Println("Successfully connected to MongoDB Atlas!")
}

func GetCollection(collectionName string) *mongo.Collection {
	return Client.Database("sync_chatapp").Collection(collectionName)
}
