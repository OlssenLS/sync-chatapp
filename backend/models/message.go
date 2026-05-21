package models

import (
	"context"
	"time"

	"github.com/OlssenLS/sync-chatapp/backend/db"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
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

func GetChatHistory(senderID, receiverID string, limit int64) ([]Message, error) {
	collection := db.GetCollection("messages")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	filter := bson.M{
		"$or": []bson.M{
			{"sender_id": senderID, "receiver_id": receiverID},
			{"sender_id": receiverID, "receiver_id": senderID},
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: -1}}).SetLimit(limit)
	cursor, err := collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var messages []Message
	if err = cursor.All(ctx, &messages); err != nil {
		return nil, err
	}

	// Reverse messages so they are in chronological order for the UI
	for i, j := 0, len(messages)-1; i < j; i, j = i+1, j-1 {
		messages[i], messages[j] = messages[j], messages[i]
	}

	return messages, nil
}

type ConversationPreview struct {
	OtherUserID   string    `bson:"other_user_id" json:"other_user_id"`
	OtherUsername string    `bson:"other_username" json:"other_username"`
	LastMessage   string    `bson:"last_message" json:"last_message"`
	Timestamp     time.Time `bson:"timestamp" json:"timestamp"`
	UnreadCount   int       `bson:"unread_count" json:"unread_count"`
}

func GetActiveConversations(userID string) ([]ConversationPreview, error) {
	collection := db.GetCollection("messages")
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pipeline := mongo.Pipeline{
		bson.D{{Key: "$match", Value: bson.M{
			"$or": []bson.M{
				{"sender_id": userID},
				{"receiver_id": userID},
			},
		}}},
		bson.D{{Key: "$sort", Value: bson.D{{Key: "timestamp", Value: -1}}}},
		bson.D{{Key: "$group", Value: bson.M{
			"_id": bson.M{
				"$cond": []interface{}{
					bson.M{"$eq": []interface{}{"$sender_id", userID}},
					"$receiver_id",
					"$sender_id",
				},
			},
			"last_message": bson.M{"$first": "$content"},
			"timestamp":    bson.M{"$first": "$timestamp"},
			"unread_count": bson.M{"$sum": bson.M{
				"$cond": []interface{}{
					bson.M{"$and": []interface{}{
						bson.M{"$eq": []interface{}{"$receiver_id", userID}},
						bson.M{"$eq": []interface{}{"$is_read", false}},
					}},
					1,
					0,
				},
			}},
		}}},
		// Explicitly project the Group ID to other_user_id immediately
		bson.D{{Key: "$project", Value: bson.M{
			"other_user_id": "$_id",
			"last_message":  1,
			"timestamp":     1,
		}}},
		// Convert to ObjectID for lookup
		bson.D{{Key: "$addFields", Value: bson.M{
			"other_obj_id": bson.M{"$toObjectId": "$other_user_id"},
		}}},
		bson.D{{Key: "$lookup", Value: bson.M{
			"from":         "users",
			"localField":   "other_obj_id",
			"foreignField": "_id",
			"as":           "user_info",
		}}},
		bson.D{{Key: "$project", Value: bson.M{
			"other_user_id": 1,
			"other_username": bson.M{
				"$ifNull": []interface{}{
					bson.M{"$arrayElemAt": []interface{}{"$user_info.username", 0}},
					"Unknown User",
				},
			},
			"last_message": 1,
			"timestamp":    1,
			"unread_count": 1,
		}}},
	}

	cursor, err := collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var conversations []ConversationPreview
	if err = cursor.All(ctx, &conversations); err != nil {
		return nil, err
	}
	return conversations, nil
}

func MarkMessagesAsRead(senderID, receiverID string) error {
	collection := db.GetCollection("messages")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{
		"sender_id":   senderID,
		"receiver_id": receiverID,
		"is_read":     false,
	}

	_, err := collection.UpdateMany(ctx, filter, bson.M{"$set": bson.M{"is_read": true}})
	return err
}
