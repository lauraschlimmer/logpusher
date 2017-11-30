# logpusher

A command line tool to import logfiles into a database. New loglines in the file
are constantly added.

To specify which parts of the logline should be extracted and imported into the target table, simply define a REGEX with named capturing groups.
Each group in the REGEX represents a column in the target table.

### Logfile and REGEX

    1475597897 lnd09 /GET / 80
    1475597905 lnd09 /GET /img/home.png 80
    1475597936 lnd07 /POST /account/new 80
    1475597953 lnd03 /GET /about 80

To store the information of the example logfile in the columns `time`, `server_name`, `http_method` and `path`, the regex could be defined as:

    $ regex="(?<time>\d+) (?<server_name>\w+) (?<http_method>\w+) (?<path>.+)"

### Usage

    $ logpusher [OPTIONS]
        -f, --file <file>                Set the path of the logfile to import
        -r, --regex <REGEX>              Set the regex
        -s, --storage <engine>           Set the storage engine
        -c, --connections <num>          Set the number of concurrent connections
            --batch_size <num>           Set the batch size
        -d, --database <db>              Select a database
        -t, --table <tbl>                Select a destination table
        -h, --host <hostname>            Set the hostname of the storage engine
        -p, --port <port>                Set the port of the storage engine
        -u, --user <username>            Set the username of the storage engine
        -q, --quiet                      Run quietly
        -?, --help                       Display this help text and exit


Note that some options may vary depending on the storage engine/database system being used

### Database support

#### SQLite

Example: Import `time` and `server_name` from the logfile into the table access_logs

    $ logpusher -s sqlite -f logs.access_logs -r $regex -d "dev.db" -t access_logs


#### MongoDB

Example: Connect to MongoDB on 127.0.0.1:27017 and import the logfile into the collection access_logs

    $ logpusher -s mongo -f logs.access_logs -r $regex -d dev -t access_logs -h localhost -p 27017


#### EventQL

Example: Connect to the EventQL server on localhost:10001 and import the logfile into the table access_logs

    $ logpusher -s eventql -f logs.access_logs -r $regex -d dev -t access_logs -h localhost -p 10001


#### PostgreSQL

Example: Connect to PostgreSQL server on localhost:5432 as user dev and import the logfile into the table access_logs

    $ logpusher -s postgresql -f logs.access_logs -r $regex -d dev -t access_logs-h localhost -p 5432 -u dev

