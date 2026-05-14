package models

import (
	"context"
	"time"

	"github.com/OlssenLS/sync-chatapp/backend/db"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type Message struct {
	ID             bson.ObjectID `bson:"_id,omitempty" json:"id"`
	SenderID       string        `bson:"sender_id" json:"sender_id"`
	ReceiverID     string        `bson:"receiver_id" json:"receiver_id"`
	ConversationID string        `bson:"conversation_id" json:"conversation_id"`
	Content        string        `bson:"content" json:"content"`
	Type           string        `bson:"type" json:"type"` // "text", "image", etc.
	Timestamp      time.Time     `bson:"timestamp" json:"timestamp"`
	IsRead         bool          `bson:"is_read" json:"is_read"`
}

type Conversation struct {
	ID           bson.ObjectID `bson:"_id,omitempty" json:"id"`
	Participants []string      `bson:"participants" json:"participants"`
	LastMessage  string        `bson:"last_message" json:"last_message"`
	UpdatedAt    time.Time     `bson:"updated_at" json:"updated_at"`
}

func SaveMessage(msg *Message) error {
	collection := db.GetCollection("messages")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	msg.Timestamp = time.Now()
	_, err := collection.InsertOne(ctx, msg)
	return err
}

func GetMessagesByConversation(convID string) ([]Message, error) {
	collection := db.GetCollection("messages")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{"conversation_id": convID}
	cursor, err := collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var messages []Message
	if err = cursor.All(ctx, &messages); err != nil {
		return nil, err
	}
	return messages, nil
}
