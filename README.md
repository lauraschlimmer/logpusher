# logpusher

A command line tool to import logfiles into a database. New loglines in the file
are constantly added.


    $ logpusher -f ngix.logs -r "(?<time>\d{10}) (?<server_name>\w+)" -t ngix.logs -h localhost -p 10001


The pattern of the logline is indicated by a regex with named capturing groups.
Each group represents a column in the target table.


### Usage
    $ logpusher [OPTIONS]

        -f, --file filename              Set the logfile to import
        -r, --regex regex                The Regex of the logline
        -t, --table table                Set the table name
        -h, --host hostname              Set the hostname
        -p, --port port                  Set the port
        -u, --user username              Set the username
            --password password          Set the password
        -d, --database db                Set the database
            --auth_token auth_token      Set the auth token
        -v, --[no-]verbose               Run verbosely
            --help                       help


### Example
Logfile

    1475682457 fr11
    1475682458 fr12
    1475682459 fr13
    1475682460 fr14
    1475682461 fr15
    1475682462 fr16

Upload the logfile to EventQL

    ruby logpusher.rb --file /tmp/logfile --regex "(?<time>\d{10}) (?<server_name>\w+)" --table log_test  -h localhost -p 10001 --database test
