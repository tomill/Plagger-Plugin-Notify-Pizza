# NAME

Plagger::Plugin::Notify::Pizza - Notify feed by pizza delivery

# SYNOPSIS

    - module: Notify::Pizza
      config:
        username: yourid@example.com 
        password: p4ssw0rd
        order: 1

# DESCRIPTION

It's joke module, but it works. So, USE AT YOUR OWN RISK.

# CONFIGURATION

- username, password

    Set your demae-can.com's ID & pass

- order

    You should set order number. Defalut is 0, that mean "not order."

- category

    With this option set, you can set the food types.

        bento 
        pizza
        sushi 
        chinese 
        european 
        curry 

    Default: pizza (year, of cource!)

- shopcode, itemcode

    You can set demae-can.com's shopcode and itemcode. You should scrapeing 
    demae-can.com's HTML to get this internal code.

- test

    This is important flag. If set 1, Notify::Pizza will not order submit.

# SAMPLE

I want Sushi. and surprise me!

    - module: Notify::Pizza
      config:
        username: hungry@example.com 
        password: p4ssw0rd
        category: shushi
        order: 1

I know what I want.

    - module: Notify::Pizza
      config:
        username: hungry@example.com 
        password: p4ssw0rd
        shopcode: G115_107 
        itemcode: 102d
        order: 2

# HUNGRY\_TO\_PIZZA RECIPE

Googleに「はらへった」と検索するとピザが届くサンプルをご紹介します。

    global:
      user_agent:
        agent: Mozilla/5.0
      timezone: Asia/Tokyo
      log:
        level: debug
    
    plugins:
      - module: Subscription::Config
        config:
          feed: https://www.google.com/searchhistory/?output=rss
    
      - module: UserAgent::AuthenRequest
        config:
          host: www.google.com:443
          auth: basic
          realm: Google Search History
          username: your-google-id
          password: your-google-password
    
    plugins:
      - module: CustomFeed::GoogleSearchHistory
        config:
          username: google-id
          password: p4ssw0rd
    
      - module: Filter::BreakEntriesToFeeds
        config:
          use_entry_title: 1
    
      - module: Filter::Rule
        rule:
          - module: Deduped
          - module: Fresh
            duration: 10 
    
      - module: Notify::Pizza
        rule:
          expression: $args->{feed}->title =~ /^はらへった/
        config:
          username: my-demae-can-id
          password: p4ssw0rd
          order: 1
          test: 1

詳しくは、[http://e8y.net/blog/2006/07/25/p126.html](http://e8y.net/blog/2006/07/25/p126.html), 
[http://e8y.net/blog/2006/07/26/p127.html](http://e8y.net/blog/2006/07/26/p127.html), 
[http://www.gihyo.co.jp/magazines/SD/contents/200610](http://www.gihyo.co.jp/magazines/SD/contents/200610)を参照ください。

# DEBUG

Notify::Pizza flush page content html to STDOUT. So, you can use this.

    ./plagger -c hungry.yaml > /var/www/scrape_test_dir/hungry.html

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# SEE ALSO

[Plagger](https://metacpan.org/pod/Plagger), [http://demae-can.com/](http://demae-can.com/)
