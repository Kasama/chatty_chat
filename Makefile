dev: database
	mix phx.server
	docker stop chatty-chat
	docker rm chatty-chat

database:
	docker run -d --rm -v $(pwd)/.data:/var/lib/postgres/data -e POSTGRES_PASSWORD=postgres -it -p 5432:5432 --name chatty-chat postgres
