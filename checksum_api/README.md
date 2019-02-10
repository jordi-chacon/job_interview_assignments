# Job interview home assignment

## Dependencies

- Elixir 1.5 or higher
- Node 7.10.1 or higher

## How to run it

```
make start-server
make run-client
make stop-server
```

# Assignment specification

## Task A - Checksum API

- Written in Elixir
- Assume this is part of a bigger project rather than a code kata when it comes to design & code quality
- Provides a HTTP Rest or GraphQL API
- Outputs JSON
- No auth necessary
- Should not rely on a database
- Does not require state persistence between restarts

The API should provide the following functionality:

#### Add numbers

Ability to accept an arbitrary number of digits which should be appended to any previously received digits to form a long number.

#### Clear numbers

Ability to clear the previously received list of digits

#### Get checksum

Calculates a checksum given the current state and returns it

BONUS - For bonus points return a timeout response if checksum can't be calculated in less than 15ms

### Checksum calculation

1. Add up the digits in odd positions and multiply by 3
2. Add up the digits in even positions
3. Add up the results of 1 and 2
4. Divide by 10 and take the remainder.
5. If the remainder is 0 final result is 0 otherwise subtract it from 10 for final result

Example:

5 4 8 9 8 5 0 3 5 4

1. 5 + 8 + 8 + 0 + 5 = 26 \* 3 = 78
2. 4 + 9 + 5 + 3 + 4 = 25
3. 78 + 25 = 103
4. 103 / 10 = 10.3 = 3
5. 10 - 3 = 7

## Task B - Test client

- Written in any language except Elixir
- Reads a test input file for commands, each row contains a single command
- Store received checksums and append to final result
- Final output should be concatenated string of checksums

Any unrecognised commands, empty lines or commands that error should be ignored

#### Commands

Add: The row begins with capital letter `A` followed by a number of digits, ex: `A18237283`

Clear: The row begins with capital letter `C`

Checksum: The row begings with letters `CS`

## Test Input

```
C
A24
CS
A47
CS
A1112
CS
C
A90
CS
C
A5218900797
8442
CS
C
A8215529768332323333588123515888912412
CS
C
A11
CS
A11
A11
A11
A11
A11
A11
11
A12
CS
A22222
A33333
CS
A3
CS
```
