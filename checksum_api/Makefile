PORT = 4000

start-server:
	cd server && make get-deps && make start-prod-server PORT=$(PORT)

stop-server:
	cd server && make stop-prod-server

run-client:
	cd client && npm install && make run PORT=$(PORT)
