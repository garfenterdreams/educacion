#!/bin/bash
set -e

# Garfenter Canvas LMS entrypoint
# Runs migrations and seeds on first startup

INIT_FLAG="/usr/src/app/tmp/.initialized"

# Wait for database to be ready
wait_for_db() {
    echo "Waiting for database..."
    for i in {1..30}; do
        if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q' 2>/dev/null; then
            echo "Database is ready!"
            return 0
        fi
        echo "Waiting for database... ($i/30)"
        sleep 2
    done
    echo "Database connection timeout"
    return 1
}

# Run migrations if not initialized
if [ ! -f "$INIT_FLAG" ]; then
    echo "=== First startup - initializing Canvas LMS ==="

    wait_for_db

    echo "Running database migrations..."
    bundle exec rails db:migrate RAILS_ENV=production || true

    echo "Running initial setup..."
    bundle exec rails db:initial_setup RAILS_ENV=production || true

    # Create admin user for Garfenter demo
    echo "Creating demo admin user..."
    bundle exec rails runner "
      account = Account.default
      account ||= Account.create!(name: 'Garfenter Demo')

      unless Pseudonym.where(unique_id: 'admin@garfenter.com').exists?
        user = User.create!(name: 'Admin')
        user.pseudonyms.create!(
          unique_id: 'admin@garfenter.com',
          password: 'GarfenterAdmin2024',
          password_confirmation: 'GarfenterAdmin2024',
          account: account
        )
        account.account_users.create!(user: user, role: Role.get_built_in_role('AccountAdmin'))
        puts 'Admin user created: admin@garfenter.com'
      end
    " RAILS_ENV=production || true

    touch "$INIT_FLAG"
    echo "=== Canvas LMS initialization complete ==="
fi

# Execute the original command (passenger start)
exec "$@"
