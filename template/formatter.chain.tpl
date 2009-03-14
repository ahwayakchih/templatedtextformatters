<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___chain/* CLASS NAME */ extends TextFormatter {

		private $_formatters;

		public function __construct(&$parent) {
			parent::__construct($parent);

			/* FORMATTERS */

			if (!is_object($this->_Parent->FormatterManager)) {
				$this->_Parent->FormatterManager = new TextformatterManager($this->_Parent);
			}
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
				'description' => __('Formatting text in the following order: %s', array('/* DESCRIPTION */')),
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		public function run($string) {
			if (strlen(trim($string)) < 1) return $string;

			if (count($this->_formatters) < 1) return stripslashes($string);

			$result = $string;
			foreach ($this->_formatters as $id => $name) {
				$formatter = $this->_Parent->FormatterManager->create($id);
				$result = $formatter->run($result);
			}

			return stripslashes($result);
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$formatters = $this->_Parent->FormatterManager->listAll();

			// Make formatters from $this->_formatters to be first and keep their order
			$temp = array();
			foreach ($this->_formatters as $id => $name) {
				$temp[$id] = $formaters[$id];
			}
			$formatters = array_merge($temp, $formatters);

			$subsection = new XMLElement('div');
			$subsection->setAttribute('class', 'subsection');
			$subsection->appendChild(new XMLElement('h3', __('Text formatters')));

			$ol = new XMLElement('ol');
			$ol->setAttribute('class', 'orderable subsection');

			foreach ($formatters as $id => $about) {
				if ($about['handle'] == '/* CLASS NAME */') continue;

				$li = new XMLElement('li');
				$li->setAttribute('class', 'unique template');

				$h4 = new XMLElement('h4', $about['name']);
				if ($about['templatedtextformatters-type']) {
					$i = new XMLElement('i');
					$i->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
					$h4->appendChild($i);
				}
				$li->appendChild($h4);

				$p = new XMLElement('p', $about['description']);
				$li->appendChild($p);

				$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));
				$ol->appendChild($li);

				if ($this->_formatters[$id]) {
					$li = new XMLElement('li');

					$h4 = new XMLElement('h4', $about['name']);
					if ($about['templatedtextformatters-type']) {
						$i = new XMLElement('i');
						$i->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
						$h4->appendChild($i);
					}
					$li->appendChild($h4);

					$p = new XMLElement('p', $about['description']);
					$li->appendChild($p);

					$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));
					$ol->appendChild($li);
				}
			}
			
			$subsection->appendChild($ol);
			$form->appendChild($subsection);

			$p = new XMLElement('p', __('Formatters will be applied in order from top to bottom.'));
			$p->setAttribute('class', 'help');
			$form->appendChild($p);
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			$description = '';
			if ($update) {
				$formatters = $this->_Parent->FormatterManager->listAll();

				// Reconstruct our current formatters array, so it's up-to-date when form is viewed right after save, without refresh/redirect
				$this->_formatters = array();
				if (is_array($_POST['fields']['formatters'])) {
					$this->_formatters = array_intersect_key($_POST['fields']['formatters'], $formatters);
					$description = implode(' &#8594; ', $this->_formatters);
				}
			}
			else if (is_array($this->_formatters) && !empty($this->_formatters)) {
				$description = implode(' &#8594; ', $this->_formatters);
			}

			if (!$description) {
				$description = __('N/A');
			}

			return array(
				'/*'.' DESCRIPTION */' => preg_replace('/[^\w\s\.-_\&\;\#\n]/i', '', $description),
				'/*'.' FORMATTERS */' => '$this->_formatters = '.preg_replace(array("/\n  /", "/\n\)\s*$/"), array("\n\t\t\t\t", "\n\t\t\t);"), var_export($this->_formatters, true)),
			);
		}
	}

