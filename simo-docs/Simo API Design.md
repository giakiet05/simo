# Base URL

- Localhost: http://localhost:8080/api/v1
- Remote: https://simo.giakiet.io.vn/api/v1

# Success response format

```json
{
	"message": "Successfully!", // for debugging
	"data": {} // data field can be any types, even null
}
```

# Error response format

```json
{
	"message": "Internal error happened!", // for debugging
	"error_code": "INTERNAL_ERROR"
}
```


# Error codes

- **INTERNAL_ERROR**: Internal server error
- **INVALID_CREDENTIALS**:


# API List
## 1. Authentication

### POST /api/v1/auth/google
Login with Google OAuth

**Request:**
```json
{
	"code": "string"
}
```

**Response (200 OK):**
```json
{
	"message": "Login successful",
	"data": {
		"access_token": "string",
		"refresh_token": "string",
		"user": {
			"id": "string",
			"google_id": "string",
			"display_name": "string",
			"email": "string",
			"avatar_url": "string",
			"monthly_budget": 1000,
			"currency": "string",
			"created_at": "timestamp",
			"updated_at": "timestamp"
		}
	}
}
```

### POST /api/v1/auth/refresh
Refresh access token

**Request:**
```json
{
	"refresh_token": "string"
}
```

**Response (200 OK):**
```json
{
	"message": "Token refreshed",
	"data": {
		"access_token": "string",
		"refresh_token": "string"
	}
}
```


### POST /api/v1/auth/logout
Logout and revoke tokens

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
	"message": "Logged out successfully",
	"data": null
}
```

## 2. Users

### GET /api/v1/users/me
Get current user info

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
	"message": "User info retrieved",
	"data": {
		"id": "string",
		"google_id": "string",
		"display_name": "string",
		"email": "string",
		"avatar_url": "string",
		"monthly_budget": 1000,
		"currency": "string",
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### PUT /api/v1/users/me
Update user settings

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"monthly_budget": 1000,
	"currency": "string"
}
```

**Response (200 OK):**
```json
{
	"message": "User updated",
	"data": {
		"id": "string",
		"google_id": "string",
		"display_name": "string",
		"email": "string",
		"avatar_url": "string",
		"monthly_budget": 1000,
		"currency": "string",
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

## 3. Statistics

### GET /api/v1/statistics
Get statistics (summary, by category, trend)

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Params:**
```
start_date: string (optional, ISO 8601 format: 2024-01-01)
end_date: string (optional, ISO 8601 format: 2024-01-31)
```

**Response (200 OK):**
```json
{
	"message": "Statistics retrieved",
	"data": {
		"summary": {
			"total_income": 5000000,
			"total_expense": 3000000,
			"balance": 2000000
		},
		"by_category": [
			{
				"category_id": "string",
				"category_name": "string",
				"type": "income",
				"total_amount": 1500000,
				"transaction_count": 5
			}
		],
		"trend": [
			{
				"date": "2024-01-01",
				"income": 500000,
				"expense": 200000
			}
		]
	}
}
```

## 4. Categories

### GET /api/v1/categories
Get all categories (no pagination needed)

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
	"message": "Categories retrieved",
	"data": [
		{
			"id": "string",
			"name": "string",
			"is_system": false,
			"created_at": "timestamp",
			"updated_at": "timestamp"
		}
	]
}
```

### POST /api/v1/categories
Create new category

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"name": "string"
}
```

**Response (201 Created):**
```json
{
	"message": "Category created",
	"data": {
		"id": "string",
		"name": "string",
		"is_system": false,
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### PUT /api/v1/categories/:id
Update category

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"name": "string"
}
```

**Response (200 OK):**
```json
{
	"message": "Category updated",
	"data": {
		"id": "string",
		"name": "string",
		"is_system": false,
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### DELETE /api/v1/categories/:id
Delete category

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
	"message": "Category deleted",
	"data": null
}
```

## 5. Transactions

### POST /api/v1/transactions
Create one or multiple transactions

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
[
	{
		"category_id": "string",
		"amount": 100000,
		"formula": "50000 + 50000",
		"note": "string (optional)",
		"type": "expense" // income/expense
	}
]
```

**Response (201 Created):**
```json
{
	"message": "Transactions created",
	"data": [
		{
			"id": "string",
			"category_id": "string",
			"recurring_config_id": null,
			"amount": 100000,
			"formula": "50000 + 50000",
			"note": "string",
			"type": "expense",
			"created_at": "timestamp",
			"updated_at": "timestamp"
		}
	]
}
```

### GET /api/v1/transactions
Get transactions list with pagination and filters

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Params:**
```
page: number (default: 1)
limit: number (default: 20)
start_date: string (optional, ISO 8601 format)
end_date: string (optional, ISO 8601 format)
category_id: string (optional)
type: string (optional, "income" or "expense")
keyword: string (optional, search in note)
min_amount: number (optional)
max_amount: number (optional)
```

**Response (200 OK):**
```json
{
	"message": "Transactions retrieved",
	"data": {
		"transactions": [
			{
				"id": "string",
				"category_id": "string",
				"recurring_config_id": null,
				"amount": 100000,
				"formula": "50000 + 50000",
				"note": "string",
				"type": "expense",
				"created_at": "timestamp",
				"updated_at": "timestamp"
			}
		],
		"pagination": {
			"page": 1,
			"limit": 20,
			"total": 100,
			"total_pages": 5
		}
	}
}
```

### PUT /api/v1/transactions/:id
Update transaction

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"category_id": "string",
	"amount": 100000,
	"formula": "50000 + 50000",
	"note": "string",
	"type": "expense"
}
```

**Response (200 OK):**
```json
{
	"message": "Transaction updated",
	"data": {
		"id": "string",
		"category_id": "string",
		"recurring_config_id": null,
		"amount": 100000,
		"formula": "50000 + 50000",
		"note": "string",
		"type": "expense",
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### DELETE /api/v1/transactions
Delete one or multiple transactions

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"ids": ["string"]
}
```

**Response (200 OK):**
```json
{
	"message": "Transactions deleted",
	"data": null
}
```

## 6. Recurring

### GET /api/v1/recurring
Get all recurring configs

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Params:**
```
is_active: boolean (optional, filter by active status)
```

**Response (200 OK):**
```json
{
	"message": "Recurring configs retrieved",
	"data": [
		{
			"id": "string",
			"category_id": "string",
			"name": "string",
			"amount": 5000000,
			"type": "income",
			"frequency": "monthly",
			"interval": 1,
			"day_of_week": null,
			"day_of_month": 1,
			"next_run": "timestamp",
			"is_active": true,
			"created_at": "timestamp",
			"updated_at": "timestamp"
		}
	]
}
```

### POST /api/v1/recurring
Create recurring config

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"category_id": "string",
	"name": "string",
	"amount": 5000000,
	"type": "income",
	"frequency": "monthly",
	"interval": 1,
	"day_of_week": null,
	"day_of_month": 1
}
```

**Response (201 Created):**
```json
{
	"message": "Recurring config created",
	"data": {
		"id": "string",
		"category_id": "string",
		"name": "string",
		"amount": 5000000,
		"type": "income",
		"frequency": "monthly",
		"interval": 1,
		"day_of_week": null,
		"day_of_month": 1,
		"next_run": "timestamp",
		"is_active": true,
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### PUT /api/v1/recurring/:id
Update recurring config

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request:**
```json
{
	"category_id": "string",
	"name": "string",
	"amount": 5000000,
	"type": "income",
	"frequency": "monthly",
	"interval": 1,
	"day_of_week": null,
	"day_of_month": 1,
	"is_active": true
}
```

**Response (200 OK):**
```json
{
	"message": "Recurring config updated",
	"data": {
		"id": "string",
		"category_id": "string",
		"name": "string",
		"amount": 5000000,
		"type": "income",
		"frequency": "monthly",
		"interval": 1,
		"day_of_week": null,
		"day_of_month": 1,
		"next_run": "timestamp",
		"is_active": true,
		"created_at": "timestamp",
		"updated_at": "timestamp"
	}
}
```

### DELETE /api/v1/recurring/:id
Delete recurring config

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
	"message": "Recurring config deleted",
	"data": null
}
```

## 7. Export

### GET /api/v1/export/excel
Export transactions to Excel file

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Params:**
```
start_date: string (optional, ISO 8601 format)
end_date: string (optional, ISO 8601 format)
category_id: string (optional)
type: string (optional, "income" or "expense")
```

**Response (200 OK):**
```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename="transactions_report.xlsx"

[Binary Excel file]
```

### GET /api/v1/export/pdf
Export transactions to PDF file

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Params:**
```
start_date: string (optional, ISO 8601 format)
end_date: string (optional, ISO 8601 format)
category_id: string (optional)
type: string (optional, "income" or "expense")
```

**Response (200 OK):**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="transactions_report.pdf"

[Binary PDF file]
```
