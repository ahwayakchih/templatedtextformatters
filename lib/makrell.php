<?php
// makrell 0.1
// php macro processor

/// Pcre library wrapper, provides more unified and convenient interface.
class PregParser
{
    /// Maximal number of passes for repeat().
    var $limit = 32; 

    /// Repeatedly apply the transformation callback $func to $text.
    /// The callback takes $text param and is supposed to return the transformed text.
    /// If count is > 0, the function is applied at most $count times.
    /// If count is < 0, the function is applied at most $this->limit times.
    /// In both cases, the function stops if the $text isn't changing anymore (i.e. callback returns the same text).
    /// The callback receives the $text as a parameter, if repeat is called with more params, they are also sent to the callback.
    function repeat($func, $count, $text) {
        $args = func_get_args();
        $args = array_slice($args, 2);
        $func = $this->_fwrap($func);
        if($count < 0)
            $count = $this->limit;
        if($count > 0) do {
            $args[0] = $text;
            $text = call_user_func_array($func, $args);
        } while(--$count && strcmp($args[0], $text));            
        return $text;
    }

    /// str_repace wrapper. Replace string $from with $to in text $text.
    function ssub($text, $from, $to) {
        return str_replace($from, $to, $text);
    }

    /// Replace $regexp with $replacement in $text. 
    /// $count is the same as in repeat().
    function gsub($text, $regexp, $replacement, $count = 1) {
        return ($count == 1) ?
            preg_replace($regexp, $replacement, $text) :
            $this->repeat('.gsub', $count, $text, $regexp, $replacement);
    }
    
    /// Replace $regexp in $text using $func as a callback function.
    /// Callback must follow preg_replace_callback rules (i.e. it takes an array of matches).
    /// Function names starting with a dot are treated as methods of $this object,
    /// i.e. <code>gfun(foo, bar, '.baz')</code> is the same as <code>gfun(foo, bar, array($this, 'baz'))</code>
    function gfun($text, $regexp, $func, $count = 1) {
        $func = $this->_fwrap($func);
        return ($count == 1) ?
            preg_replace_callback($regexp, $func, $text) :
            $this->repeat('.gfun', $count, $text, $regexp, $func);
    }
    function _fwrap($func) {
        if(!is_array($func) && $func[0] == '.') 
            return array(&$this, substr($func, 1));
        return $func;
    }
    
    /// Replace the keys of $pairs with the values of $pairs.
    /// $pairs is an associative array, whose keys are regexps and values are replacements.
    function ksub($text, $pairs, $count = 1) {
        return ($count == 1) ?
            preg_replace(array_keys($pairs), array_values($pairs), $text) :
            $this->repeat('.gsub', $count, $text, array_keys($pairs), array_values($pairs));
    }
    
    /// Replace the keys of $pairs by calling corresponding callbacks.
    /// $pairs is an associative array, whose keys are regexps and values are callback functions.
    function kfun($text, $pairs, $count = 1) {
        foreach($pairs as $regexp => $func)
            $pairs[$regexp] = $this->_fwrap($func);
        return ($count == 1) ?
            $this->_kfun($text, $pairs) :
            $this->repeat('._kfun', $count, $text, $pairs);
    }
    function _kfun($text, $pairs) {
        foreach($pairs as $regexp => $func)
            $text = preg_replace_callback($regexp, $func, $text);
        return $text;
    }
    
    /// preg_match wrapper. Returns an array of matches or an empty array.
    function match($text, $regexp) {
        if(!preg_match($regexp, $text, $m))
            return array();
        return $m;
    }

    /// preg_match_all wrapper. Returns an array of matches or an empty array.
    function match_all($text, $regexp, $flags = 0) {
        if(!preg_match_all($regexp, $text, $m, $flags))
            return array();
        return $m;
    }
}

/// "Virtual clipboard" functions.
class PregClipboard extends PregParser
{
    /// Array of strings that are currently in clipboard.
    /// Can be freely changed.
    var $data = array();
    
    var $_uid;
    
    /// uid is an unique id of this clipboard.
    /// It's recommended to use characters in range \\x01-\\x07
    function PregClipboard($uid = 0) {
        static $_c = 0;
        $this->_uid = preg_quote($uid ? $uid : chr(++$_c));
    }
    
    /// Find strings in $text that match $regexp, replace them with 'invisible' markers 
    /// (consisting of the characters in range \\x01-\\x19) and copy them to the clipboard.
    /// If $group != 0, copies $group-th captured regexp subgroup (by default, the whole matched string).
    function cut($text, $regexp, $group = 0) {
        $this->_catgrp = $group;
        return $this->gfun($text, $regexp, '._cut');
    }
    function _cut($m) {
        return $this->copy($m[$this->_catgrp]);
    }
    
    /// Place the string in the clipboard and return a marker for it.
    function copy($str) {
        $this->data[] = $str;
        $n = strval(count($this->data) - 1);
        return $this->_uid . "\x08" .
            strtr($n, '0123456789', "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19") . "\x08";
    }
    
    /// Insert strings from the clipboard back into the text.
    function paste($text) {
        return $this->gfun($text, "~($this->_uid)\x08([\\x10-\\x19]+)\\x08~", '._paste', -1);
    }
    function _paste($m) {
        $n = intval(strtr($m[2], "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19", '0123456789'));
        return isset($this->data[$n]) ? $this->data[$n] : '';
    }
    
    /// Clear the clipboard.
    function clear() {
        $this->data = array();
    }
}

/// Macro parser.
class MakrellParser extends PregParser
{
    /// list of built-in types (assoc array type_name => regexp)
    var $types = array(
        'int'    => '\d+',
        'string' => '(?:\"(?:\\\\.|[^\"])*\")|(?:\'(?:\\\\.|[^\'])*\')',
        'id'     => '[a-zA-Z_]\w*',
        'alpha'  => '[a-zA-Z]+',
        'alnum'  => '[a-zA-Z0-9]+',
        'ns'     => '\S+',
        'any'    => '[\s\S]+?',
        'nobr'   => '[^\n]+',
        'br'     => '[\n]+',
    );
    var $_basedir = '';
    var $_macros = array();
    
    /// Process the $text according to makrell rules and return parsed text.
    function parse($text) {
        $text = $this->repeat('._parse', -1, $text);
        if(isset($this->_quotes)) {
            $text = $this->_quotes->paste($text);
            unset($this->_quotes);
        }
        return $text;
    }
    
    /// Parse the text in a file and return parsed text.
    function parse_file($path) {
        $this->_basedir = dirname(realpath($path));
        return $this->parse(file_get_contents($path));
    }
    
    function _parse($text) {
        $text = $this->repeat('._extract_macros', -1, $text);
        $text = $this->repeat('._expand_macros', -1, $text);    
        return $text;
    }
    function _extract_macros($text) {
        // find longest {{{ 
        if(!$m = $this->match_all($text, '~\{{2,}~'))
            return $text;
        $len = max(array_map('strlen', $m[0]));
        while($len > 1) {
            // replace {{{ }}} with \x1a \x1b to make regexp simpler
            $cx = array("\x1a", "\x1b");
            $cs = array(str_repeat('{', $len), str_repeat('}', $len));
            $t = $this->ssub($text, $cs, $cx);
            // replace expressions that have $len braces
            $t = $this->gfun($t, "~(?:^|\n) ([^\n\x1a]*) \x1a ([^\x1a\x1b]*) \x1b~xi", '._extract_one');
            // put dangling braces back
            $t = $this->ssub($t, $cx, $cs);
            // if expressions were found and parsed - return right now 
            // this function will be restarted by the caller
            if(strcmp($t, $text))
                return $t;
            // no, $len braces don't form any valid expression, try with less braces
            $len--;
        } 
        return $text;
    }
    function _extract_one($m) {
        list(, $key, $body) = $m;
        if(strlen(trim($key))) {
            // a macro, like "foo {{ bar }}"
            $this->macro($key, $body);
            return '';
        }
        // a command like "{{ include blah }}"
        if(!$m = $this->match($body, "~^\s*(\w+)(|\s.*)$~"))
            return ''; // no command word -- comment. remove it.
        $cmd = "command_{$m[1]}";
        if(!method_exists($this, $cmd))
            return ''; // no such command -- remove
        return $this->$cmd($m[2]);
    }
    function _expand_macros($text) {
        foreach($this->_macros as $key => $body) {
            $this->_macrobody = $body;
            $text = $this->gfun($text, $key, '._expand_one');
        }
        return $text;
    }
    function _expand_one($m) {
        $body = $this->_macrobody;
        foreach($m as $var => $value)
            $body = $this->ssub($body, "\x1a{$var}\x1a", $value);
        return $body;
    }

    /// Define the new macro with the key $key and body $body.
    function macro($key, $body) {
        if(!strlen($key = trim($key)))
            return;
        $this->_macrovars = array();
        if($key[0] != '/') {
            // if pattern is not a regexp
            $key = preg_quote($key, '/');
            // whitespace matches spaces+tabs
            $key = $this->gsub($key, '~\s+~', '[ \\t]+');
            // if pattern ends with an untyped var, it's assumed to be 'nobr'
            if($this->match($key, '~@[a-z]+$~')) 
                $key .= '\:nobr';
            // a variable is @foo or @foo:bar or @:bar
            $key = $this->gfun($key, '~@([a-z]*\\\\:[0-9a-z]+|[a-z]+)~', '._parse_var_in_key');
            $key = "/$key/";
        }
        // reduce trailing whitespace in body
        $body = $this->gsub($body, '~^\s+|\s+$~', ' ');
        // parse vars in body
        $this->_macros[$key] = $this->_parse_vars_in_body($body);
    }
    function _parse_var_in_key($m) {
        $s = explode('\\:', $m[1]);
        $this->_macrovars[] = $s[0];
        $re = isset($s[1]) && isset($this->types[$s[1]]) ?  $this->types[$s[1]] : '.+?';
        return "($re)";
    }
    function _parse_vars_in_body($body) {
        $body = $this->gsub($body, '~@(\d\d?)~', "\x1a$1\x1a");
        foreach($this->_macrovars as $n => $var) {
            if(strlen($var))
                $body = $this->ssub($body, "@$var", "\x1a" . ($n + 1) . "\x1a");
        }
        return $body;
    }
    
    /// Built-in 'type' command.
    function command_type($body) {
        // {{ type email .+?@.+ }}
        if($m = $this->match(trim($body), "~^(\w+)(.*)$~"))
            $this->types[$m[1]] = trim($m[2]);
        return '';
    }
    /// Built-in 'include' command.
    function command_include($body) {
        // {{ include foobar }}
        $path = trim($body, " \t\r\n\'\"");
        if(strlen($this->_basedir) && !$this->match($path, '~^([a-z]:)?[/\\\\]~i'))
            $path = $this->_basedir . '/' . $path;
        return file_get_contents($path);
    }
    /// Built-in 'quote' command.
    function command_quote($body) {
        // {{ quote dont expand macros here }}
        if(!isset($this->_quotes))
            $this->_quotes = new PregClipboard("\x1c");
        return $this->_quotes->copy($body);
    }
    
    function _dbg($text) {
        $text = preg_replace('~[\x00-\x08\x0b-\x1f\x7F-\xFF]~e', "sprintf('\\x%02x', ord('$0'))", $text);
        $q = "";
        foreach(explode("\n", $text) as $n => $s)
            $q .= sprintf("%04d: %s\n", $n + 1, $s);
        return $q;
    }
}

/// Main class, template engine.
class Makrell extends MakrellParser
{
    /// If not empty, parsed templates will be cached in this directory
    var $cachedir = '';
    
    var $_vars = array();

    /// When called with two arguments, sets a template variable $var to $value.
    /// When called with one argument (which should be a hash of variables) adds all variables to the template.
    function set($var, $value = null) {
        if(is_array($var))
            $this->_vars = array_merge($this->_vars, $var);
        else
            $this->_vars[$var] = $value;
    }
    
    /// Parse and include the template file and return the evaluated text.
    function render($path) {
        if(strlen($this->cachedir))
            return $this->_render_file($this->_parse_cache($path));
        else 
            return $this->_render_text($this->parse_file($path));
    }
    
    function _parse_cache($path) {
        $path = realpath($path);
        $cachedir = rtrim(strtr($this->cachedir, '\\', '/'), '/');
        if(strlen($cachedir)) $cachedir .= '/';
        $outpath =  $cachedir . 'mak_' . md5($path);
        if(!is_readable($outpath) || filemtime($path) >= filemtime($outpath)) {
            $text = $this->parse_file($path);
            $fp = fopen($outpath, "wb");
            fwrite($fp, $text);
            fclose($fp);
        }
        return $outpath;
    }
    function _render_file($__path) {
        extract($this->_vars);
        ob_start();
        include($__path);
        return ob_get_clean();
    }
    function _render_text($___text) {
        extract($this->_vars);
        ob_start();
        eval("?>$___text");
        return ob_get_clean();
    }
}
?>