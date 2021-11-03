# xtrRfc

xtrRfc.sh exracts all RFCs (incl. URLs and abstracts) from a given text.


### Features

- Tries hard to detect all RFC terms (like RFC 1 or RFC-1 or rfc 1) in a given text.
- Consolidates found RFCs: RFC 1, RFC 001 and RFC 0001 will be converted to RFC 0001.
- Sorts found RFCs according to the frequency in given text.
- Adds abstract from [RFC index](https://www.ietf.org/download/rfc-index.txt) to each RFC.
- bash-only script, no Python or Perl needed (tested with bash 5.0.17).



### Usage

```bash

$ ./xtrRfc.sh 

Extract all RFCs from a given text:

./xtrRfc.sh --txt=... [--rfc=...]

--txt=<file>   # extract all RFCs from <file>
--txt=STDIN    # extract all RFCs from STDIN
--txt=-        # extract all RFCs from STDIN

--rfc=<file>   # get RFC abstracts from <file>
               # instead of https://www.ietf.org/download/rfc-index.txt

Examples:

# read text from /tmp/foo.txt
# read rfc abstracts from https://www.ietf.org/download/rfc-index.txt
./xtrRfc.sh --txt=/tmp/foo.txt

# read text from STDIN
# read rfc abstracts from https://www.ietf.org/download/rfc-index.txt
man date | ./xtrRfc.sh --txt=STDIN

# read text from STDIN
# read rfc abstracts from /tmp/rfc.txt
man date | ./xtrRfc.sh --txt=- --rfc=/tmp/rfc.txt
```


### Example

```bash
$ man date | ./xtrRfc.sh --txt=STDIN

Downloading https://www.ietf.org/download/rfc-index.txt

RFC 3339
  Occurrences in text: 2
  https://datatracker.ietf.org/doc/html/3339 -> Date and Time on the Internet: Timestamps. G. Klyne, C. Newman. July 2002. (Format: TXT, HTML) (Status: PROPOSED STANDARD) (DOI: 10.17487/RFC3339) 

RFC 5322
  Occurrences in text: 1
  https://datatracker.ietf.org/doc/html/5322 -> Internet Message Format. P. Resnick, Ed.. October 2008. (Format: TXT, HTML) (Obsoletes RFC2822) (Updates RFC4021) (Updated by RFC6854) (Status: DRAFT STANDARD) (DOI: 10.17487/RFC5322) 

```

