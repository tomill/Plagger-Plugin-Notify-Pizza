package Plagger::Plugin::Notify::Pizza;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Mechanize;

our %category = (
    bento    => '01',
    pizza    => '02', # default
    sushi    => '03',
    chinese  => '04',
    european => '05',
    curry    => '11',
);

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&deliver,
    );
    $self->{hungry} = 1;
}
 
sub deliver {
    my ($self, $context, $args) = @_;
    
    return unless $self->{hungry};      # I'm not hungry.
    return unless $self->conf->{order}; # don't want order.
     
    my $mech = new Plagger::Mechanize;
    
    $self->{hungry} = 0;
    
    # access...
    $context->log(info => "Going to Demae-Can...");
    $mech->get('http://demae-can.com/index.php?action=dream_login_index');
    unless ($mech->success) {
        $context->log(error => "Connect faled.");
        return;   
    }

    # login...
    $mech->field('id'   => $self->conf->{username});
    $mech->field('pass' => $self->conf->{password});
    $mech->click;
    if ($mech->content !~ m{http://demae-can.com/search/shop_list.html\?word=0}) {
        $context->log(error => "Login failed.(id=$self->conf->{username})");
        print $mech->content;
        return;   
    }
    
    # select deliver-to  
    my $deliver_to = $self->conf->{deliver_to} || 0;
    $mech->get("/search/shop_list.html?word=$deliver_to");
    unless ($mech->success) {
        $context->log(error => "Can't find group list.(deliver_to=$deliver_to)");
        print $mech->content;
        return;   
    }
    
    my $shopcode; 
    if ($self->conf->{shopcode}) {
        $shopcode = $self->conf->{shopcode};
        $context->log(info => "Select shop.(shopcode=$shopcode)");
    } else {
        # select category...
        my $cate = $category{ $self->conf->{category} || 'pizza' };
        $context->log(info => "Select category.(category_id=$cate)");
        unless ($mech->follow_link(url_regex => qr{shop_list2\.html\?cate=${cate}&code=\d+&mode=0})) {
            $context->log(error => "Can't find shop list.(category_id=$cate)");
            print $mech->content;
            return;
        }
        if ($mech->content =~ m{
            <img[ ]src="../images/search_img/some.gif"
            .*?
            <a[ ]href=http://demae-can.com/index\.php\?shopcode=([^&]+)&noid=0
            .*?
            <img[ ]src="../images/search_img/sonota.gif"
        }x) {
            $shopcode = $1;
        } else {
            $context->log(error => "Can't find shop.");
            print $mech->content;
            return;
        }
    }
    # get menu...
    $mech->get("/order/disp_menu.html?shopcode=${shopcode}&noid=&groupe=1");
    unless ($mech->success) {
        $context->log(error => "Can't find menu.(shopcode=$shopcode)");
        print $mech->content;
        return;
    }
    
    # choice item
    my $itemcode;
    $mech->form_number(1);
    if ($self->conf->{itemcode}) {
        $itemcode = $self->conf->{itemcode};
        $mech->field('itemcode[0]' => $itemcode);
    } else {
        $itemcode = $mech->value('itemcode[0]');    
    }
    $mech->click;
    $context->log(info => "Select item.(itemcode=$itemcode)");
    unless ($mech->success) {
        $context->log(error => "Can't open item.");
        print $mech->content;
        return;
    }
    
    # order...
    my $order = $self->conf->{order}; 
    $context->log(info => "Order.(order=$order)");
    $mech->form_number(1);
    $mech->field('order_num', $order);
    $mech->click;
    unless ($mech->success) {
        $context->log(error => "Can't go to cart.");
        print $mech->content;
        return;
    }
    # confirm...
    $mech->form_number(1);
    $mech->click;
    unless ($mech->success) {
        $context->log(error => "Can't go to confirm view.");
        print $mech->content;
        return;
    }
    
    if ($self->conf->{test}) { # stop.
        print $mech->content;
        $context->log(info => "test=1, not order.");
        return; 
    }
    
    # submit!
    $mech->field('pass', $self->conf->{password});
    $mech->click;
    if ($mech->success) {
        $context->log(info => join '',
            "Order successfly.(",
            "deliver_to=$deliver_to,",
            "shopcode=$shopcode,",
            "itemcode=$itemcode,",
            "order=$order)"
        );
    } else {
        $context->log(error => "Can't order.");
        return;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Plagger::Plugin::Notify::Pizza - Notify feed by pizza delivery

=head1 SYNOPSIS

  - module: Notify::Pizza
    config:
      username: yourid@example.com 
      password: p4ssw0rd
      order: 1

=head1 DESCRIPTION

It's joke module, but it works. So, USE AT YOUR OWN RISK.

=head1 CONFIGURATION

=over 4

=item username, password

Set your demae-can.com's ID & pass

=item order

You should set order number. Defalut is 0, that mean "not order."

=item category

With this option set, you can set the food types.

    bento 
    pizza
    sushi 
    chinese 
    european 
    curry 

Default: pizza (year, of cource!)

=item shopcode, itemcode

You can set demae-can.com's shopcode and itemcode. You should scrapeing 
demae-can.com's HTML to get this internal code.

=item test

This is important flag. If set 1, Notify::Pizza will not order submit.

=back

=head1 SAMPLE

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

=head1 HUNGRY_TO_PIZZA RECIPE

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

詳しくは、L<http://e8y.net/blog/2006/07/25/p126.html>, 
L<http://e8y.net/blog/2006/07/26/p127.html>, 
L<http://www.gihyo.co.jp/magazines/SD/contents/200610>を参照ください。

=head1 DEBUG

Notify::Pizza flush page content html to STDOUT. So, you can use this.

    ./plagger -c hungry.yaml > /var/www/scrape_test_dir/hungry.html

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 SEE ALSO

L<Plagger>, L<http://demae-can.com/>

=cut
