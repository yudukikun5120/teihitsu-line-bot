# Teihitsu Training LINE Bot

Kanji learning on the LINE platform with Kanji Teihitsu questions.

### LINE Official Account Manager

- [https://manager.line.biz/account/@664jquts](https://manager.line.biz/account/@664jquts)

### LINE Web Profile

- [https://page.line.me/664jquts](https://page.line.me/664jquts)

## Development

### Reference 

- https://github.com/line/line-bot-sdk-ruby
- [https://developers.line.biz/flex-simulator/](https://developers.line.biz/flex-simulator/)
- [https://developers.line.biz/console/](https://developers.line.biz/console/)
- [https://web.deta.sh/home/yudukikun5120/default/micros/teihitsu-api](https://web.deta.sh/home/yudukikun5120/default/micros/teihitsu-api)
- [https://devcenter.heroku.com/ja/articles/logging](https://devcenter.heroku.com/ja/articles/logging)

### Tasks

- [x]  Changed LINE account name to _Kanji Teihitsu Training (Admin Approved)_.
- [ ]  Addition of problem groups

### Sequence diagram

```mermaid
sequenceDiagram
		autonumber

		participant c as client
		participant b as LINE Bot
		participant db as database

    c->>b: Press the "Start" button
		b->>db: Request an problem
		db->>db: Randomly select a problem
		db->>b: Submit a problem
		b->>c: Send a message for an problem card
		c->>b: Submit the answer
		alt For correct answer
        b->>c: Send a correct answer card message
    else For wrong answer
				b->>db: Write down a record of the wrong answer
        b->>c: Send a message on the wrong card
        b->>c: Send the same issue card message
				c->>c: Return to ❻
    end
```

### State diagram

```mermaid
stateDiagram-v2

[*] --> waiting
waiting --> waiting: answer the problem

```

### Databases

Use Postgres 14 as the database.

```mermaid
erDiagram
    USER_CURRENT_STATUS {
        integer state
        integer item_id
        charvar user_id
    }
```
