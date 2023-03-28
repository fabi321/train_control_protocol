import json
from subprocess import Popen, PIPE
from dotenv import load_dotenv
from os import getenv
import re
from typing import Optional

REQUIRE_REGEX: re.Pattern = re.compile(r'''require\(["']([a-zA-Z0-9_]+)["']\)''')
TEMPLATE_REGEX: re.Pattern = re.compile(r'\{\{([a-zA-Z0-9_]+)\}\}')
LUA_FILES: list[str] = ['queue.lua', 'bus_switch.lua', 'chacha20.lua', 'handshake.lua', 'router.lua']
COMPILED: list[str] = ['bus_switch', 'handshake', 'router']


class Lib:
	def __init__(self):
		self.snippets: dict[str, str] = {}

	def add_and_resolve_snippet(self, name: str, snippet: str):
		while match := REQUIRE_REGEX.search(snippet):
			required_snippet: Optional[str] = self.snippets.get(match.group(1))
			if not required_snippet:
				raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
			snippet = snippet[:match.start()] + required_snippet + snippet[match.end() + 1:]
		self.snippets[name] = snippet

	def add_from_file(self, filename: str):
		with open(filename) as f:
			self.add_and_resolve_snippet(filename.split('.')[0], f.read())


def parse_json() -> str:
	with open('protocol.json') as f:
		protocol_definition = json.load(f)
	result_str: str = ''
	for id, definition in protocol_definition.items():
		result_str += id
		if definition.get('sync'):
			result_str += 'S'
		elif definition.get('sync_newer'):
			result_str += 's'
		if definition.get('invert'):
			result_str += 'I'
		if definition.get('add'):
			result_str += 'A'
		if definition.get('ignore_rear'):
			result_str += 'R'
		result_str += '='
	return result_str[:-1]


def minify(text: str) -> str:
	process: Popen = Popen(['lua5.4', 'minify.lua', 'minify', '-'], stdin=PIPE, stderr=PIPE, stdout=PIPE)
	result = process.communicate(text.encode())
	if result[1]:
		print(result[1].decode())
		raise ValueError('Broken code')
	return result[0].decode()


def escape(text: str) -> str:
	return text\
		.replace('<', '&lt;')\
		.replace('>', '&gt;')\
		.replace('&', '&amp;')\
		.replace('"', '&quot;')\
		.replace("'", '&apos;')\
		.replace('{{key}}', getenv('KEY'))


def compile_file(text: str) -> str:
	text = minify(text)
	text = escape(text)
	return text


def compile() -> dict[str, str]:
	lib: Lib = Lib()
	for file in LUA_FILES:
		lib.add_from_file(file)
	return {name: compile_file(lib.snippets[name]) for name in COMPILED}


def main():
	load_dotenv()
	compiled: dict[str, str] = compile()
	compiled['protocol'] = parse_json()
	compiled['trusted_mode'] = (getenv('TRUSTED_MODE') or 'true').lower()
	assert compiled['trusted_mode'] in ('true', 'false'), 'Only true or false are possible settings for TRUSTED_MODE'
	with open('hull.xml') as f:
		hull: str = f.read()
	while match := TEMPLATE_REGEX.search(hull):
		required_snippet: Optional[str] = compiled.get(match.group(1))
		if not required_snippet:
			raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
		hull = hull[:match.start()] + required_snippet + hull[match.end():]
	with open('train_controller.xml', 'w') as f:
		f.write(hull)


if __name__ == "__main__":
	main()
