### 1. Backend Architecture
- **Models**: Defines the data shape and DB interaction.
- **Controllers**: Handles HTTP request parsing and business logic.
- **Routes**: Decouples the API surface from the implementation.
- **Utils**: Contains shared logic like JWT signing.

### 2. Security
- **Password Hashing**: We use `bcrypt` with a cost factor of 14.
- **JWT (JSON Web Tokens)**: Used for stateless authentication.

### 3. Database: MongoDB (NoSQL)
- **Schema-less but Structured**: While MongoDB is flexible, `User` model enforces a structure (Email, Username, PasswordHash).
- **Indexing**: Unique indexes on `username` and `email` to prevent duplicates at the database level.
- **Connection Pooling**: Managed in the `db/` package to ensure efficient resource usage.

### 4. Frontend
- **Form Validation**: Implemented via regex to reduce unnecessary API calls (filtering invalid emails/short passwords on the client side).
- **Rendering Engines**: We explicitly disabled **Impeller** in favor of **Skia** for emulator stability.
- **Asynchronous UI**: Using `setState` with `_isLoading` flags to handle the bridge between UI and HTTP services without freezing the app.

---

### Q1: "How do you handle 'Race Conditions' during registration?"
> *Answer:* Currently, we check for existing users in the controller, look for **Unique Indexes** in MongoDB to ensure the database itself rejects duplicates as a final line of defense.

### Q2: "Why JWT and not Sessions?"
> *Answer:* JWT allows the backend to be **horizontally scalable**. Since the server doesn't need to "remember" the user in its own memory, we could run 10 instances of the backend, and any of them could validate the user's token.

### Q3: "What happens if the MongoDB connection drops mid-operation?"
> *Answer:* We use **Context with Timeout** (`context.WithTimeout`) in Go. This prevents the backend from hanging forever if the database is unresponsive, returning an error to the user after 5–10 seconds instead.

### Q4: "How are you preventing brute-force attacks on the Login?"
> *Answer:* Currently, we don't have rate limiting. A senior would suggest implementing a "Middleware" that limits login attempts per IP address using something like Redis or a simple in-memory counter.

---
