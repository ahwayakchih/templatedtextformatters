<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___regex/* CLASS NAME */ extends TextFormatter {

		private $_patterns;
		private $_description;

		public function __construct(&$parent) {
			parent::__construct($parent);

			/* PATTERNS */

			$this->_description = '/* DESCRIPTION */';
		}
		
		public function about() {
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
				
		public function run($string) {
			if (strlen(trim($string)) < 1) return $string;

			if (count($this->_patterns) < 1) return stripslashes($string);

			return stripslashes(preg_replace(array_keys($this->_patterns), array_values($this->_patterns), $string));
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$label = Widget::Label(__('Description'));
			$label->appendChild(Widget::Input('fields[description]', $this->_description ? $this->_description : $_POST['fields']['description']));
			$form->appendChild($label);

			$subsection = new XMLElement('div');
			$subsection->setAttribute('class', 'subsection');
			$p = new XMLElement('p', __('Patterns and replacements'));
			$p->setAttribute('class', 'label');
			$subsection->appendChild($p);

			$ol = new XMLElement('ol');
			$ol->setAttribute('id', 'fields-duplicator');

			$temp = $this->_patterns;
			$temp[''] = '';
			foreach ($temp as $pattern => $replacement) {
				$li = new XMLElement('li');
				$li->setAttribute('class', ($pattern ? 'unique field-regex' : ' template field-regex'));
				$li->appendChild(new XMLElement('h4', __('Replace')));

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

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			if ($update) {
				// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
				$this->_patterns = array();
				$this->_description = str_replace(array('\'', '"'), array('&#039;', '&quot;'), $_POST['fields']['description']);

				$index = 0;
				$code = '';
				if (!empty($_POST['fields']['patterns']) && count($_POST['fields']['patterns']) == count($_POST['fields']['replacements'])) {
					$this->_patterns = array_combine($_POST['fields']['patterns'], $_POST['fields']['replacements']);
				}
			}

			return array(
				'/*'.' DESCRIPTION */' => $this->_description,
				'/*'.' PATTERNS */' => '$this->_patterns = '.preg_replace(array("/\n  /", "/\n\)\s*$/"), array("\n\t\t\t\t", "\n\t\t\t);"), var_export($this->_patterns, true)),
			);
		}
	}

