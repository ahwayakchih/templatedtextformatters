<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.

	if (!class_exists('FormatterChain')) {
		class FormatterChain {
			public static $stack = array();
		}
	}

	Class formatter___chain/* CLASS NAME */ extends TextFormatter {

		private $_formatters;
		private static $_recursion;

		public function __construct() {
			if (!is_array(self::$_recursion)) self::$_recursion = array();

			/* FORMATTERS */;

		}
		
		public function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.4',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		public function run($string) {
			if (strlen(trim($string)) < 1) return $string;

			if (count($this->_formatters) < 1) return stripslashes($string);

			if (isset(self::$_recursion[__CLASS__]) && self::$_recursion[__CLASS__] > 0) {
				return "<!-- CHAIN RECURSION ERROR\n*\n*\t"
					.__("Detected text formatter recursion on %s", array("\n*\t/* NAME */ (/* CLASS NAME */)"))
					."\n*\t"
					.__("Formatter was run by %s", array("\n*\t".end(FormatterChain::$stack)))
					."\n*\n//-->"
					.stripslashes($string);
			}

			self::$_recursion[__CLASS__]++;
			FormatterChain::$stack[] = '/* NAME */ (/* CLASS NAME */)';
			$result = $string;
			foreach ($this->_formatters as $id => $name) {
				$formatter = TextformatterManager::create($id);
				$result = $formatter->run($result);
			}
			array_pop(FormatterChain::$stack);
			self::$_recursion[__CLASS__]--;

			return stripslashes($result);
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$formatters = TextformatterManager::listAll();

			// Make formatters from $this->_formatters to be first and keep their order
			$temp = array();
			foreach ($this->_formatters as $id => $name) {
				$temp[$id] = $formatters[$id];
			}
			$formatters = array_merge($temp, $formatters);

			$p = new XMLElement('p', __('Formatters will be applied in order from top to bottom.'));
			$p->setAttribute('class', 'help');
			$form->appendChild($p);

			$subsection = new XMLElement('div', NULL, array('class' => 'frame templatedtextformatter-duplicator'));

			$ol = new XMLElement('ol');
			$ol->setAttribute('data-add', __('Add formatter'));
			$ol->setAttribute('data-remove', __('Remove formatter'));

			foreach ($formatters as $id => $about) {
				if ($about['handle'] == '/* CLASS NAME */') continue;

				$li = new XMLElement('li');
				$li->setAttribute('class', 'unique template field-'.$about['handle']);
				$li->setAttribute('data-type', $about['handle']);

				$header = new XMLElement('header');
				$h4 = new XMLElement('h4', '<strong>' . $about['name'] . '</strong>' . ($about['templatedtextformatters-type'] ? ' <span class="type">' . $about['templatedtextformatters-type'] . '</span>' : ''));
				$header->appendChild($h4);
				$li->appendChild($header);

				$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));

				$div = new XMLElement('div');
				$p = new XMLElement('p', $about['description']);
				$div->appendChild($p);
				if ($about['templatedtextformatters-type']) {
					$p = new XMLElement('p');
					$p->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
					$div->appendChild($p);
				}
				$li->appendChild($div);

				$ol->appendChild($li);

				if ($this->_formatters[$id]) {
					$li = new XMLElement('li');
					$li->setAttribute('class', 'unique field-'.$about['handle']);
					$li->setAttribute('data-type', $about['handle']);

					$header = new XMLElement('header');
					$h4 = new XMLElement('h4', '<strong>' . $about['name'] . '</strong>' . ($about['templatedtextformatters-type'] ? ' <span class="type">' . $about['templatedtextformatters-type'] . '</span>' : ''));
					$header->appendChild($h4);
					$li->appendChild($header);

					$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));

					$div = new XMLElement('div');	
					$p = new XMLElement('p', $about['description']);
					$div->appendChild($p);
					if ($about['templatedtextformatters-type']) {
						$p = new XMLElement('p');
						$p->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
						$div->appendChild($p);
					}
					$li->appendChild($div);

					$ol->appendChild($li);
				}
			}
			
			$subsection->appendChild($ol);
			$form->appendChild($subsection);
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			$description = '';
			if ($update) {
				$formatters = TextformatterManager::listAll();

				// Reconstruct our current formatters array, so it's up-to-date when form is viewed right after save, without refresh/redirect
				$this->_formatters = array();
				if (is_array($_POST['fields']['formatters'])) {
					$this->_formatters = array_intersect_key($_POST['fields']['formatters'], $formatters);
					$description = implode(' → ', $this->_formatters);
				}
			}
			else if (is_array($this->_formatters) && !empty($this->_formatters)) {
				$description = implode(' → ', $this->_formatters);
			}

			if (empty($description)) {
				$description = __('N/A');
			}
			else {
				$description = __('Formatting text in the following order: %s', array($description));
			}

			return array(
				'/*'.' DESCRIPTION */' => preg_replace('/^\'|\'$/', '', var_export($description, true)),
				'/*'.' FORMATTERS */' => '$this->_formatters = '.preg_replace(array("/\n  /", "/\n\)\s*$/"), array("\n\t\t\t\t", "\n\t\t\t);"), var_export($this->_formatters, true)),
			);
		}
	}

