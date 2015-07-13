# StorjBot price ticker
# (c) Robin Beckett 2014

# Melotic: https://www.melotic.com/api/markets/sjcx-btc/ticker
# Poloniex: https://poloniex.com/public?command=returnTicker

package require json
package require http
package require tls

::http::register https 443 [ list ::tls::socket -tls1 true ]

set meloticUrl "https://www.melotic.com/api/markets/sjcx-btc/ticker"
set poloniexUrl "https://poloniex.com/public?command=returnTicker"
set blockscanUrl "http://api.blockscan.com/api2?module=address&action=balance&asset=SJCX&btc_address="

proc commify {num {sep ,}} {
    while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
    return $num
}

proc helpCall {nick uhost handle chan text} {
        puthelp "PRIVMSG $nick :Hi, I'm StorjBot, coded by SubWolf."
        puthelp "PRIVMSG $nick :Commands you can use in #storj:"
        puthelp "PRIVMSG $nick :.markets           - Retrieve latest SJCX/BTC prices for the Melotic and Poloniex exchanges."
        puthelp "PRIVMSG $nick :.melotic           - Retrieve latest SJCX/BTC price for Melotic."
        puthelp "PRIVMSG $nick :.poloniex          - Retrieve latest SJCX/BTC price for Poloniex."
        puthelp "PRIVMSG $nick :Commands available via query to me (or in channel if you want everyone to see):"
        puthelp "PRIVMSG $nick :.balance <address> - Get the SJCX balance for an address."
        puthelp "PRIVMSG $nick :If you find using my services useful/rewarding, please send some SJCX to my tip jar address - 1CLpaycSodetj8Lx9GExc1rjSXDUG7V5n2"
}

proc getMelotic {nick uhost handle chan text} {
	global meloticUrl
        set xml [http::data [http::geturl $meloticUrl -timeout 30000]]
        set latestPriceFloat [dict get [json::json2dict $xml] "latest_price"]
	set latestPriceInt [format {%0.8f} [expr double($latestPriceFloat)]]

        puthelp "PRIVMSG $chan :Melotic SJCX/BTC\: $latestPriceInt"
}

proc getPoloniex {nick uhost handle chan text} {
	global poloniexUrl
        set xml [http::data [http::geturl $poloniexUrl -timeout 30000]]
        set latestPriceFloat [dict get [dict get [json::json2dict $xml] "BTC_SJCX"] "last"]
        set latestPriceInt [format {%0.8f} [expr double($latestPriceFloat)]]

        puthelp "PRIVMSG $chan :Poloniex SJCX/BTC\: $latestPriceInt"
}

proc sjcxAddressGood {scjxaddress} {
	if {[string length $sjcxaddress] < 26 || [string length $sjcxaddress] > 36} {
		return 0;
	}
	return 1;
}

proc getMarkets {nick uhost handle chan text} {
	getMelotic $nick $uhost $handle $chan $text
	getPoloniex $nick $uhost $handle $chan $text
}

proc getBalance {nick uhost handle chan text} {
	global blockscanUrl
	set text [string trim $text]
        if {[string length $text] < 26 || [string length $text] > 36} {
                puthelp "PRIVMSG $chan :Invalid SJCX address!"
                return 0;
        }

	putlog "$blockscanUrl$text"
	set xml [http::data [http::geturl "$blockscanUrl$text" -timeout 30000]]
        set latestPriceFloat [dict get [lindex [dict get [json::json2dict $xml] "data"] 0] "balance"]
        set latestPriceInt [commify [format {%0.5f} [expr double($latestPriceFloat)]]]

        puthelp "PRIVMSG $chan :Balance for $text: $latestPriceInt SJCX"
}

proc getBalanceMsg {nick uhost handle text} {
        global blockscanUrl
        set text [string trim $text]
        if {[string length $text] < 26 || [string length $text] > 36} {
                puthelp "PRIVMSG $nick :Invalid SJCX address!"
                return 0;
        }

        putlog "$blockscanUrl$text"
        set xml [http::data [http::geturl "$blockscanUrl$text" -timeout 30000]]
        set latestPriceFloat [dict get [lindex [dict get [json::json2dict $xml] "data"] 0] "balance"]
        set latestPriceInt [commify [format {%0.5f} [expr double($latestPriceFloat)]]]

        puthelp "PRIVMSG $nick :Balance for $text: $latestPriceInt SJCX"

}

proc toTheMoon {nick uhost handle chan text} {
	puthelp "PRIVMSG $chan :So cool. Very storj. Wow."
}

bind pub - ".melotic" getMelotic
bind pub - ".poloniex" getPoloniex
bind pub - ".markets" getMarkets
bind pub - ".balance" getBalance
bind msg - ".balance" getBalanceMsg
bind pub - ".moon" toTheMoon
bind pub - "!help" helpCall
bind pub - ".help" helpCall

putlog "StorjBot loaded..."


