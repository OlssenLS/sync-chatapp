package main

import (
    "fmt"
    "net/http"
    "github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        return true
    },
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
    ws, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        fmt.Println("Error upgrading:", err)
        return
    }
    defer ws.Close()

    fmt.Println("Client connected!")

    for {
        messageType, p, err := ws.ReadMessage()
        if err != nil {
            fmt.Println("Error reading:", err)
            break
        }
        fmt.Println("Received: %s\n", p)
        if err := ws.WriteMessage(messageType, p); err != nil {
            fmt.Println("Error writing:", err)
            break
        }
    }
}

func main() {
    http.HandleFunc("/ws", handleConnections)
    fmt.Println("Chat server started on :8080")
    http.ListenAndServe(":8080", nil)
}