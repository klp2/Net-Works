use strict;
use warnings;

use Math::BigInt;
use Math::Int128 qw(uint128);
use Test::Fatal;
use Test::More 0.88;

use Net::Works::Address;

{
    my $ip = Net::Works::Address->new_from_string( string => '1.2.3.4' );
    is(
        $ip->as_string(),
        '1.2.3.4',
        '->as_string returns string passed to constructor'
    );

    my $next = $ip->next_ip();
    isa_ok(
        $next,
        'Net::Works::Address',
        'return value of ->next_ip'
    );

    is(
        $next->as_string(),
        '1.2.3.5',
        'next ip after 1.2.3.4 is 1.2.3.5'
    );

    my $prev = $ip->previous_ip();
    isa_ok(
        $prev,
        'Net::Works::Address',
        'return value of ->previous_ip'
    );

    is(
        $prev->as_string(),
        '1.2.3.3',
        'previous ip before 1.2.3.4 is 1.2.3.3'
    );

    is(
        "$ip",
        '1.2.3.4',
        'stringification of address object works'
    );

    cmp_ok(
        $ip, '<', $next,
        'numeric overloading (<) on address objects works'
    );

    cmp_ok(
        $next, '>', $ip,
        'numeric overloading (>) on address objects works'
    );

    my $same_ip = Net::Works::Address->new_from_string( string => '1.2.3.4' );

    cmp_ok(
        $ip, '==', $same_ip,
        'numeric overloading (==) on address objects works'
    );

    is(
        $ip <=> $same_ip,
        0,
        'comparison overloading (==) on address objects works'
    );
}

{
    my @ips = map { Net::Works::Address->new_from_string( string => $_ ) } qw(
        ::123.0.0.4
        ::1.2.3.4
        2003::
        ::255.255.255.255
        abcd::1000
        ::127.0.98.25
        ::127.0.98.24
    );

    my @sorted = qw(
        ::1.2.3.4
        ::123.0.0.4
        ::127.0.98.24
        ::127.0.98.25
        ::255.255.255.255
        2003::
        abcd::1000
    );

    is_deeply(
        [ map { $_->as_string() } sort { $a <=> $b } @ips ],
        \@sorted,
        'address objects sort numerically'
    );

    is_deeply(
        [ map { $_->as_string() } sort { $a cmp $b } @ips ],
        \@sorted,
        'address objects sort alphabetically'
    );
}

{
    my $ip = Net::Works::Address->new_from_string( string => '192.168.0.255' )
        ->next_ip();
    is(
        $ip->as_string(),
        '192.168.1.0',
        '->next_ip wraps to the next ip address'
    );
}

{
    my $ip = Net::Works::Address->new_from_string( string => 'ffff::a:1234' );
    is(
        $ip->as_string(),
        'ffff::a:1234',
        '->as_string returns string passed to constructor'
    );

    my $prev = $ip->previous_ip();
    is(
        $prev->as_string(),
        'ffff::a:1233',
        'previous ip before ffff::a:1234 is ffff::a:1233'
    );

    my $next = $ip->next_ip();
    is(
        $next->as_string(),
        'ffff::a:1235',
        'next ip after ffff::a:1234 is ffff::a:1235'
    );
}

{
    my $ip = Net::Works::Address->new_from_string(
        string => 'ffff::0000:000a:1234' );
    is(
        $ip->as_string(),
        'ffff::a:1234',
        '->as_string returns compact form of IPv6'
    );
}

{
    for my $address (
        qw( 255.255.255.255 ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff )) {

        my $ip = Net::Works::Address->new_from_string( string => $address );

        like(
            exception { $ip->next_ip() },
            qr/\Q$address is the last address in its range/,
            'cannot call ->next_ip on the last address in a range'
        );
    }
}

{
    for my $address (qw( 0.0.0.0 ::0 )) {

        my $ip = Net::Works::Address->new_from_string( string => $address );

        like(
            exception { $ip->previous_ip() },
            qr/\Q$address is the first address in its range/,
            'cannot call ->previous_ip on the first address in a range'
        );
    }
}

{
    my $ip = Net::Works::Address->new_from_integer(
        integer => 0,
        version => 4,
    );

    is(
        $ip->as_string(),
        '0.0.0.0',
        'new_from_integer(0), IPv4'
    );

    is(
        $ip->as_integer(),
        0,
        'as_integer returns 0'
    );

    is(
        $ip->as_bit_string(),
        '0' x 32,
        'as_bit_string returns 0x32'
    );

    $ip = Net::Works::Address->new_from_integer(
        integer => 2**32 - 1,
        version => 4,
    );

    is(
        $ip->as_string(),
        '255.255.255.255',
        'new_from_integer(2**32 - 1), IPv4'
    );

    is(
        $ip->as_integer(),
        2**32 - 1,
        'as_integer returns 2**32 - 1'
    );

    is(
        $ip->as_bit_string(),
        '1' x 32,
        'as_bit_string returns 1x32'
    );

    $ip = Net::Works::Address->new_from_integer(
        integer => 0,
        version => 6,
    );

    is(
        $ip->as_string(),
        '::0',
        'new_from_integer(0), IPv6'
    );

    is(
        $ip->as_integer(),
        0,
        'as_integer returns 0, IPv6'
    );

    is(
        $ip->as_bit_string(),
        '0' x 128,
        'as_bit_string returns 0x128'
    );

    $ip = Net::Works::Address->new_from_integer(
        integer => 2**32 - 1,
        version => 6,
    );

    is(
        $ip->as_string(),
        '::255.255.255.255',
        'new_from_integer(2**32 - 1), IPv6'
    );

    is(
        $ip->as_bit_string(),
        ( '0' x 96 ) . ( '1' x 32 ),
        'as_bit_string returns 0x96 . 1x32'
    );

    is(
        $ip->as_integer(),
        2**32 - 1,
        'as_integer returns 2**32 - 1, IPv6'
    );
}

for my $one ( uint128(1), Math::BigInt->bone() ) {
    subtest 'using ' . ref($one) . ' integer' => sub {

        my $max_128 = ( $one * 2 )**128 - $one;
        my $ip      = Net::Works::Address->new_from_integer(
            integer => $max_128,
            version => 6,
        );

        is(
            $ip->as_string(),
            'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
            'new_from_integer(2**128 - 1), IPv6'
        );

        is(
            $ip->as_integer(),
            $max_128,
            'as_integer returns 2**128 - 1, IPv6'
        );

        is(
            $ip->as_bit_string(),
            '1' x 128,
            'as_bit_string returns 1x128'
        );

        $ip = Net::Works::Address->new_from_integer(
            integer => $one,
            version => 4,
        );

        is(
            $ip->as_string(),
            '0.0.0.1',
            'as_string returns 0.0.0.1'
        );
    };
}

{
    my $e = exception {
        Net::Works::Address->new_from_integer(
            integer => uint128(2)**33,
            version => 4
        );
    };

    like(
        $e,
        qr/\d+ \Qis not a valid integer for an IP address/,
        'new_from_integer blows up when giving a value larger than 2**32 -1 with version => 4'
    );
}

{
    my %tests = (
        '::0'         => '0.0.0.0',
        '::2'         => '0.0.0.2',
        '::ffff'      => '0.0.255.255',
        '::ffff:ffff' => '255.255.255.255',
    );

    for my $raw ( sort keys %tests ) {
        my $ip = Net::Works::Address->new_from_string(
            string  => $raw,
            version => 6,
        );

        is(
            $ip->as_ipv4_string(),
            $tests{$raw},
            "$raw as IPv4 is $tests{$raw}"
        );
    }
}

{
    my $ip = Net::Works::Address->new_from_string(
        string  => '::1:ffff:ffff',
        version => 6,
    );

    like(
        exception { $ip->as_ipv4_string() },
        qr/\QCannot represent IP address larger than 2**32-1 as an IPv4 string/,
        'cannot represent an IPv6 address >= 2**32 as an IPv4 string'
    );
}

{
    @DummyPackageName::ISA = qw( Net::Works::Address );

    my $ip = DummyPackageName->new_from_string( string => '1.2.3.4' );

    my $next = $ip->next_ip();
    isa_ok(
        $next,
        'DummyPackageName',
    );

    my $prev = $ip->previous_ip();
    isa_ok(
        $prev,
        'DummyPackageName',
    );
}

{
    # chain through to overriden new_from_integer correctly
    @AnotherDummyPackageName::ISA = qw( Net::Works::Address );

    sub AnotherDummyPackageName::new_from_integer {
        my $class = shift;
        return $class->new_from_string( string => '2.2.2.2' );
    }

    my $ip = AnotherDummyPackageName->new_from_string(
        string  => '::0',
        version => 6,
    );
    is( $ip->as_ipv4_string, '2.2.2.2', 'test overloaded method' );
}

done_testing();
