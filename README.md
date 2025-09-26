# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Developer setup (recommended)

We provide a `bin/setup` helper to get a developer environment ready. It will:

- check `.ruby-version` and print guidance if your Ruby mismatches
- run `bundle install`
- attempt to create and migrate the development DB
- run `db:seed`

Run:

```bash
./bin/setup
```

If your `config/database.yml` references a DB user that doesn't exist (e.g. `user_501_health`), either create that DB user on your Postgres server or set environment variables `DATABASE_USER` and `DATABASE_PASSWORD` before running `bin/setup`.

### Quick manual steps (if you prefer)

1. Install Ruby (rbenv recommended) and set the version from `.ruby-version`.
2. gem install bundler && bundle install
3. Start Postgres (Homebrew on macOS): `brew services start postgresql`
4. Create DB user if needed:

```sql
-- in psql as a superuser
CREATE ROLE user_501_health WITH LOGIN PASSWORD 'password_501_health';
CREATE DATABASE health_app_development OWNER user_501_health;
```

5. Run migrations & seeds:

```bash
bin/rails db:create db:migrate db:seed
```

## Docker (recommended for team reproducibility)

If you prefer Docker so every developer gets the same environment, add a simple `docker-compose.yml` with a Postgres service and the app. Example (minimal):

```yaml
version: '3.8'
services:
	db:
		image: postgres:14
		environment:
			POSTGRES_USER: dev_user
			POSTGRES_PASSWORD: dev_pass
			POSTGRES_DB: health_app_development
		ports:
			- "5433:5432"
		volumes:
			- db-data:/var/lib/postgresql/data
	web:
		build: .
		command: bash -lc "bundle install && bin/rails db:create db:migrate db:seed && bin/rails s -b 0.0.0.0"
		volumes:
			- .:/app
		ports:
			- "3000:3000"
		depends_on:
			- db
volumes:
	db-data:
```

Start with:

```bash
docker compose up --build
```

This approach ensures everyone runs the same DB and Ruby environment in containers and avoids touching shared/production databases.

