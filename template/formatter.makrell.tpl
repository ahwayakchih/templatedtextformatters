<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___makrell/* CLASS NAME */ extends TextFormatter {

		private $_macros;

		private static $_makrell;

		public function __construct(&$parent) {
			parent::__construct($parent);

			/* MAKRELL MACROS */;
		}
		
		public function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '0.1',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		public function run($string) {
			if (!$string) return $string;

			if (!isset(self::$_makrell)) {
				if (!file_exists(EXTENSIONS . '/templatedtextformatters/lib/makrell.php')) {
					self::$_makrell = false;
				}
				else {
					@include_once(EXTENSIONS . '/templatedtextformatters/lib/makrell.php');
					self::$_makrell = class_exists('Makrell');
				}
			}

			if (self::$_makrell) {
				$m = new Makrell;
				$string = $m->parse($this->_macros . $string);
			}

			return $string;
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$div = new XMLElement('div');
			$label = Widget::Label(__('Macro definitions'));
			$label->appendChild(Widget::Textarea('fields[makrell_macros]', 10, 50, $this->_macros ? $this->_macros : $_POST['fields']['makrell_macros']));
			$div->appendChild($label);
			$div->appendChild(new XMLElement('p', __('<a href="http://stereofrog.com/files/makrell_samples.php" target="_blank">Macro definitions</a> will be prepended to formatted text before passing it to Makrell parser.'), array('class' => 'help')));
			$form->appendChild($div);
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			if ($update) {
				$this->_macros = (isset($_POST['fields']['makrell_macros']) ? trim($_POST['fields']['makrell_macros']) : '');
			}

			return array(
				'/*'.' MAKRELL MACROS */' => '$this->_macros = '.var_export($this->_macros, true),
			);
		}
	}

