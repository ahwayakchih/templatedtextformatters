<?php

	Class formatter/* CLASS NAME */ extends TextFormatter {
		private $_patterns;
		private $_description;

		function __construct(&$parent) {
			parent::__construct($parent);

			/* PATTERNS */

			$this->_description = '/* DESCRIPTION */';
		}
		
		function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.3',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		function run($string) {
			if (strlen(trim($string)) < 1) return $string;

			if (count($this->_patterns) < 1) return stripslashes($string);

			return stripslashes(preg_replace(array_keys($this->_patterns), array_values($this->_patterns), $string));
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		function ttf_form(&$form, &$page) {
			$label = Widget::Label(__('Description'));
			$label->appendChild(Widget::Input('fields[description]', $this->_description ? $this->_description : $fields['description']));
			$form->appendChild($label);

			$subsection = new XMLElement('div');
			$subsection->setAttribute('class', 'subsection');
			$subsection->appendChild(new XMLElement('h3', __('Patterns and replacements')));

			$ol = new XMLElement('ol');

			$temp = $this->_patterns;
			$temp[''] = '';
			foreach ($temp as $pattern => $replacement) {
				$li = new XMLElement('li');
				$li->setAttribute('class', ($pattern ? 'unique' : ' template'));
				$li->appendChild(new XMLElement('h4', '#'));

				$div = new XMLElement('div');
				$div->setAttribute('class', 'group');

				$label = Widget::Label(__('Pattern'));
				$label->appendChild(Widget::Input('fields[patterns][]', htmlentities($pattern, ENT_QUOTES, 'UTF-8')));
				$div->appendChild($label);

				$label = Widget::Label(__('Replacement'));
				$label->appendChild(Widget::Input('fields[replacements][]', htmlentities($replacement, ENT_QUOTES, 'UTF-8')));
				$div->appendChild($label);

				$li->appendChild($div);
				$ol->appendChild($li);
			}

			$subsection->appendChild($ol);
			$form->appendChild($subsection);

			$p = new XMLElement('p', __('Wrap patterns with slashes, e.g., "/pattern_here/". You can use backreferences in replacement. Syntax for pattern and replacement is exactly the same as in <a href="http://www.php.net/manual/en/function.preg-replace.php" target="_blank">preg_replace()</a> function in PHP.'));
			$p->setAttribute('class', 'help');
			$form->appendChild($p);
		}

		// Hook called by TemplatedTextFormatters when saving formatter
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		function ttf_tokens() {
			// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
			$this->_patterns = array();
			$this->_description = str_replace(array('\'', '"'), array('&#039;', '&quot;'), $_POST['fields']['description']);

			$index = 0;
			$code = '';
			while ($_POST['fields']['patterns'][$index]) {
				$this->_patterns[$_POST['fields']['patterns'][$index]] = $_POST['fields']['replacements'][$index];
				$code .= '\''.preg_replace('/([^\\\\])\'/', '$1\\\'', $_POST['fields']['patterns'][$index]).'\' => \''.preg_replace('/([^\\\\])\'/', '$1\\\'', $_POST['fields']['replacements'][$index]).'\',';
				$index++;
			}

			return array(
				'/*'.' DESCRIPTION */' => $this->_description,
				'/*'.' PATTERNS */' => '$this->_patterns = array('.$code.');'
			);
		}
	}

