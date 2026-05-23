# 🛒 SmartShop — AI-Powered Product Search

A production-grade Rails 8 e-commerce search engine that understands natural language using RAG (Retrieval-Augmented Generation). Search in plain English and get intelligent, context-aware results.

---

## 🌟 Live Demo

> Search *"gift for 5 year old under ₹2000"* and it actually understands what you mean — not just keyword matching.

---

## 🏗️ Architecture

```
User Query (natural language)
         │
         ▼
┌─────────────────────────┐
│    Rails Controller     │
│    SearchController     │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    EmbeddingService     │  ← Ollama (nomic-embed-text)
│    query → vector       │    Converts text to 768-dim array
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    pgvector Search      │  ← PostgreSQL + pgvector
│    cosine similarity    │    Finds semantically closest products
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    SearchService        │  ← Groq API (Llama 3.3 70B)
│    LLM re-ranking       │    Re-ranks and explains results
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    Rails View           │  ← Hotwire/Turbo/Stimulus
│    Results UI           │    Live search + category filter
└─────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Backend | Ruby on Rails 8.1 | Web framework |
| Database | PostgreSQL 16 | Primary data store |
| Vector Search | pgvector extension | Semantic similarity search |
| Embeddings | Ollama (nomic-embed-text) | Text → vector conversion |
| LLM | Groq API — Llama 3.3 70B | Query understanding + re-ranking |
| Frontend | Hotwire (Turbo + Stimulus) | Live search, SPA-like UX |
| Auth (planned) | Devise | User authentication |
| Background Jobs | Solid Queue | Async job processing |
| Caching | Solid Cache | Response caching |
| WebSockets | Solid Cable | Real-time features |

---

## ✨ Features

### 🔍 AI-Powered Search
- **Natural language search** — search like you talk: *"running shoes for men under ₹5000"*
- **Semantic matching** — finds *"footwear for jogging"* when you search *"running shoes"* — meaning-based, not keyword-based
- **LLM re-ranking** — Llama 3.3 re-ranks results and explains why each product matches
- **Query understanding** — displays AI's interpretation of your search intent

### 💰 Smart Price Intelligence
- **Budget detection** — automatically detects price constraints from natural language
- **Price notes** — labels products as *"Within your budget"* or *"Slightly over your budget"*
- **Budget-aware ranking** — prioritises in-budget products

### 🗂️ Navigation & Filtering
- **Category sidebar** — filter results by Electronics, Footwear, Toys & Games, Books, Home & Kitchen, Sports & Fitness, Fashion, Beauty & Health
- **Conversational follow-up** — refine searches naturally: *"show me cheaper ones"*, *"only electronics"*
- **Search history** — recent searches saved in session with one-click repeat
- **Clear history** — remove search history with one click

### ⚡ Live Search (Development)
- **Hotwire Stimulus** — results update as you type (400ms debounce)
- **Turbo Streams** — partial page updates without full reload
- **Environment-aware** — live search enabled in development, disabled in production to respect API limits

### 🎨 UI/UX
- **Responsive design** — works on desktop and mobile
- **Welcome screen** — suggestion chips for quick searches
- **Product cards** — clean cards with name, category, price, relevance reason
- **Orange theme** — SmartShop brand identity throughout

---

## 📁 Project Structure

```
smartshop/
├── app/
│   ├── controllers/
│   │   └── search_controller.rb      # Search + history management
│   ├── models/
│   │   └── product.rb                # Product model + vector search
│   ├── services/
│   │   ├── embedding_service.rb      # Ollama API integration
│   │   └── search_service.rb         # RAG pipeline + LLM reranking
│   ├── views/
│   │   └── search/
│   │       ├── index.html.erb        # Main search UI
│   │       └── _results.html.erb     # Results partial (Turbo)
│   └── javascript/
│       └── controllers/
│           └── search_controller.js  # Stimulus live search
├── config/
│   ├── routes.rb                     # App routes
│   └── database.yml                  # PostgreSQL config
├── db/
│   ├── migrate/
│   │   └── xxxx_create_products.rb  # Products table + pgvector
│   └── products_generated.json      # Generated product data
└── lib/
    └── tasks/
        ├── generate_products.rb      # Groq product generation
        └── seed_products.rb          # Ollama embedding + seeding
```

---

## 🚀 Setup & Installation

### Prerequisites
- Ruby 3.4.6
- Rails 8.1
- PostgreSQL 16
- Ollama (local LLM server)
- Groq API key (free tier)

### Step 1 — Clone & Install
```bash
git clone https://github.com/ashwinsantebennur/smartshop.git
cd smartshop
bundle install
```

### Step 2 — Environment Variables
Create `.env` in the project root:
```bash
GROQ_API_KEY=your_groq_api_key_here
OLLAMA_URL=http://localhost:11434
```

Get your free Groq API key at [console.groq.com](https://console.groq.com)

### Step 3 — Setup Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull embedding model
ollama pull nomic-embed-text

# Verify
ollama list
```

### Step 4 — Database Setup
```bash
rails db:create
rails db:migrate
```

### Step 5 — Generate & Seed Products
```bash
# Generate ~300 products via Groq API (takes ~5 mins)
ruby lib/tasks/generate_products.rb

# Seed with embeddings via Ollama (takes ~15 mins)
ruby lib/tasks/seed_products.rb
```

### Step 6 — Start Server
```bash
rails server
```

Visit `http://localhost:3000` 🎉

---

## 🔑 Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GROQ_API_KEY` | ✅ Yes | Groq API key for LLM re-ranking |
| `OLLAMA_URL` | ✅ Yes | Ollama server URL (default: http://localhost:11434) |
| `DATABASE_URL` | Production only | PostgreSQL connection URL |

---

## 🧪 Key Concepts

### RAG Pipeline (Retrieve → Augment → Generate)
1. **Retrieve** — Convert query to embedding vector, find similar products in pgvector
2. **Augment** — Pass retrieved products + original query to LLM
3. **Generate** — LLM re-ranks, explains relevance, detects budget

### Vector Embeddings
- Each product description is converted to a 768-dimension vector
- Similar meanings produce similar vectors
- pgvector's `<=>` operator finds closest vectors using cosine similarity
- `nomic-embed-text` model via Ollama runs locally — free and private

### Service Objects
- `EmbeddingService` — single responsibility: text → vector
- `SearchService` — orchestrates the full RAG pipeline

---

## 🎯 Search Examples

| Query | What AI Finds |
|---|---|
| `"gift for 5 year old under 2000"` | Toys in budget |
| `"footwear for jogging"` | Running shoes (semantic match) |
| `"laptop for college student"` | Student-friendly laptops |
| `"healthy cooking under 8000"` | Air fryers, pressure cookers in budget |
| `"affordable smartphone with good camera"` | Mid-range phones with camera focus |

---

## 🗺️ Roadmap

### Planned Features
- [ ] User authentication (Devise)
- [ ] Wishlist / saved products
- [ ] Product ratings & reviews
- [ ] Admin dashboard (product management)
- [ ] REST API endpoints
- [ ] RSpec test suite
- [ ] Price drop alerts (Solid Queue)
- [ ] Real-time chat support (Solid Cable)
- [ ] Product image support (Active Storage)
- [ ] Personalised recommendations

---

## 📊 Data

- **293 products** across 8 categories
- Generated using Groq API (Llama 3.3 70B)
- Each product has a 768-dimension embedding vector
- Categories: Electronics, Footwear, Toys & Games, Books, Home & Kitchen, Sports & Fitness, Fashion, Beauty & Health

---

## 👨‍💻 Author

**Ashwin Santebennur**
Senior Software Engineer — Ruby on Rails, PostgreSQL, AI/ML Integration

- GitHub: [@ashwinsantebennur](https://github.com/ashwinsantebennur)
- Built as a portfolio project demonstrating RAG architecture in production Rails apps

---

## 📄 License

MIT License — feel free to use this as a reference for your own AI-powered Rails applications.