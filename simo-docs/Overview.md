
## App name: Simo (Simple Money Management)
## Project goal: 
To create a minimalist, ad-free money management app that focuses on the most essential features, avoiding the complexity and subscription models of mainstream apps. 

## Core requirements
- Minimalistm: Focus strictly on high-value, simple features.
- ~~Multi-platform:~~ Mobile-first, ~~followed by Web and Desktop~~
- Languages: English and Vietnamese

## Feature list
1. Record income/expenses 
	- Support multiple items in a single entry.
	- Support basic math operations: +, -, *, /
	- Each item includes an amount of money (math operation supported), one category and an optional note.
	- Save the raw math expression (e.g., 10 + 20) alongside the result for future reference. 
2. Generate intuitive charts based on transaction history. 
3. ~~Export reports to Excel of PDF formats.~~
4. Customizable categories.
5. Set monthly limits and receive notifications when approaching the threshold.
6. Search and filter logs by date, categories or keywords
7. Automatically log fixed income or expenses on the chosen date of month (first day, last day, day 15th,...)
8. Support multiple currencies (VND and USD)
9. Quick summary dashboard: Total income, total expense, balance 
10. ~~Cloud synchronization when the devices are online.~~ 
11. In-app chatbot (Future enhancement)

## Non-functional requirements
- The app must launch in less than 2 seconds on mobile devices.
- Calculation results and UI updates should be near-instant (latency < 100ms) to ensure a smooth UX.
- The mobile app must provide full offline functionality. Users should be able to record transactions without an internet connection, with data syncing automatically once back online
- The server must be designed to handle concurrent requests.
- User data must be isolated, no one can access another's financial records.
- All API must be encrypted via HTTPS/TLS.
- Ensure "Atomic Transaction" - if a multi-item entry fails halfway, no partial data should be saved to the database. 
- The UI must support dynamic switching between English and Vietnamese without requiring an app restart