<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___xsskiller/* CLASS NAME */ extends TextFormatter {

		public function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.1',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		public function run($val) {
			$val = trim($val);
			if (strlen($val) < 1) return $val;

			// Code from: http://kallahar.com/smallprojects/php_xss_filter_function.php by Kallahar
			// remove all non-printable characters. CR(0a) and LF(0b) and TAB(9) are allowed
			// this prevents some character re-spacing such as <java\0script>
			// note that you have to handle splits with \n, \r, and \t later since they *are* allowed in some inputs
			$val = preg_replace('/([\x00-\x08,\x0b-\x0c,\x0e-\x19])/', '', $val);
			
			// straight replacements, the user should never need these since they're normal characters
			// this prevents things like <IMG SRC=&#X40&#X61&#X76&#X61&#X73&#X63&#X72&#X69&#X70&#X74&#X3A&#X61&#X6C&#X65&#X72&#X74&#X28&#X27&#X58&#X53&#X53&#X27&#X29>
			$search = 'abcdefghijklmnopqrstuvwxyz';
			$search .= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
			$search .= '1234567890!@#$%^&*()';
			$search .= '~`";:?+/={}[]-_|\'\\';
			for ($i = 0; $i < strlen($search); $i++) {
				// ;? matches the ;, which is optional
				// 0{0,7} matches any padded zeros, which are optional and go up to 8 chars
			
				// &#x0040 @ search for the hex values
				$val = preg_replace('/(&#[xX]0{0,8}'.dechex(ord($search[$i])).';?)/i', $search[$i], $val); // with a ;
				// &#00064 @ 0{0,7} matches '0' zero to seven times
				$val = preg_replace('/(&#0{0,8}'.ord($search[$i]).';?)/', $search[$i], $val); // with a ;
			}
			
			// now the only remaining whitespace attacks are \t, \n, and \r
			$ra1 = Array('javascript', 'vbscript', 'expression', 'applet', 'meta', 'xml', 'blink', 'link', 'style', 'script', 'embed', 'object', 'iframe', 'frame', 'frameset', 'ilayer', 'layer', 'bgsound', 'title', 'base');
			$ra2 = Array('onabort', 'onactivate', 'onafterprint', 'onafterupdate', 'onbeforeactivate', 'onbeforecopy', 'onbeforecut', 'onbeforedeactivate', 'onbeforeeditfocus', 'onbeforepaste', 'onbeforeprint', 'onbeforeunload', 'onbeforeupdate', 'onblur', 'onbounce', 'oncellchange', 'onchange', 'onclick', 'oncontextmenu', 'oncontrolselect', 'oncopy', 'oncut', 'ondataavailable', 'ondatasetchanged', 'ondatasetcomplete', 'ondblclick', 'ondeactivate', 'ondrag', 'ondragend', 'ondragenter', 'ondragleave', 'ondragover', 'ondragstart', 'ondrop', 'onerror', 'onerrorupdate', 'onfilterchange', 'onfinish', 'onfocus', 'onfocusin', 'onfocusout', 'onhelp', 'onkeydown', 'onkeypress', 'onkeyup', 'onlayoutcomplete', 'onload', 'onlosecapture', 'onmousedown', 'onmouseenter', 'onmouseleave', 'onmousemove', 'onmouseout', 'onmouseover', 'onmouseup', 'onmousewheel', 'onmove', 'onmoveend', 'onmovestart', 'onpaste', 'onpropertychange', 'onreadystatechange', 'onreset', 'onresize', 'onresizeend', 'onresizestart', 'onrowenter', 'onrowexit', 'onrowsdelete', 'onrowsinserted', 'onscroll', 'onselect', 'onselectionchange', 'onselectstart', 'onstart', 'onstop', 'onsubmit', 'onunload');
			$ra = array_merge($ra1, $ra2);

			$found = true; // keep replacing as long as the previous round replaced something
			while ($found == true) {
				$val_before = $val;
				for ($i = 0; $i < sizeof($ra); $i++) {
					$pattern = '/';
					for ($j = 0; $j < strlen($ra[$i]); $j++) {
						if ($j > 0) {
							$pattern .= '(';
							$pattern .= '(&#[xX]0{0,8}([9ab]);)';
							$pattern .= '|';
							$pattern .= '|(&#0{0,8}([9|10|13]);)';
							$pattern .= ')*';
						}
						$pattern .= $ra[$i][$j];
					}
					$pattern .= '/i';
					//$replacement = substr($ra[$i], 0, 2).'<x>'.substr($ra[$i], 2); // add in <> to nerf the tag
					if ($ra[$i]{0} == 'o' && $ra[$i]{1} == 'n') $replacement = 'xss';
					else $replacement = trim(preg_replace('/\w/', '\\0-', $ra[$i]), '-');
					$val = preg_replace($pattern, $replacement, $val); // filter out the hex tags
					if ($val_before == $val) {
						// no replacements were made, so exit the loop
						$found = false;
					}
				}
			}

			// TODO: escape/remove href values like: href="attack();" because they will be executed even though there is no "javascript:" part there.

			return $val;
		}
/*
		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			return array();
		}
*/
	}

