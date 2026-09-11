#!/usr/bin/env bun

import { readdirSync } from 'node:fs'
import { resolve } from 'node:path'

const publicDir = process.argv[2] ?? 'static'
const staticRoot = resolve(process.cwd(), publicDir)
const threeRoot = resolve(process.cwd(), 'node_modules/three')
const documents = new Map()
let buffer = Buffer.alloc(0)

const respond = (id, result) => {
	const body = JSON.stringify({ jsonrpc: '2.0', id, result })
	process.stdout.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`)
}

const saveDocument = (uri, text) => documents.set(uri, text.split('\n'))

const completions = ({ textDocument, position }) => {
	const line = documents.get(textDocument.uri)?.[position.line]
	const path = line?.slice(0, position.character).match(/['"`]((?:\/|three\/)[^'"`]*)$/)?.[1]
	if (!path) return []

	const slash = path.lastIndexOf('/')
	const partial = path.slice(slash + 1)
	const root = path.startsWith('three/') ? threeRoot : staticRoot
	const rootOffset = path.startsWith('three/') ? 'three/'.length : 1
	const directory = resolve(root, path.slice(rootOffset, slash + 1))
	if (directory !== root && !directory.startsWith(`${root}/`)) return []

	const range = {
		start: { line: position.line, character: position.character - partial.length },
		end: position,
	}

	try {
		return readdirSync(directory, { withFileTypes: true })
			.filter((entry) => entry.name.startsWith(partial))
			.map((entry) => {
				const isDirectory = entry.isDirectory()
				const item = {
					label: entry.name,
					kind: isDirectory ? 19 : 17,
					// textEdit: { range, newText: entry.name + (isDirectory ? '/' : '') },
					textEdit: { range, newText: entry.name },
				}
				if (isDirectory)
					item.command = { title: 'triggerSuggest', command: 'editor.action.triggerSuggest' }
				return item
			})
	} catch {
		return []
	}
}

const handlers = {
	initialize: () => ({
		capabilities: {
			textDocumentSync: 1,
			completionProvider: { triggerCharacters: ['/'] },
		},
	}),
	shutdown: () => null,
	'textDocument/didOpen': ({ textDocument }) => saveDocument(textDocument.uri, textDocument.text),
	'textDocument/didChange': ({ textDocument, contentChanges }) =>
		saveDocument(textDocument.uri, contentChanges.at(-1)?.text ?? ''),
	'textDocument/didClose': ({ textDocument }) => documents.delete(textDocument.uri),
	'textDocument/completion': completions,
}

process.stdin.on('data', (chunk) => {
	buffer = Buffer.concat([buffer, chunk])

	while (true) {
		const headerEnd = buffer.indexOf('\r\n\r\n')
		if (headerEnd < 0) return

		const length = Number(
			buffer
				.subarray(0, headerEnd)
				.toString()
				.match(/Content-Length: *(\d+)/i)?.[1]
		)
		const bodyStart = headerEnd + 4
		const bodyEnd = bodyStart + length
		if (buffer.length < bodyEnd) return

		const message = JSON.parse(buffer.subarray(bodyStart, bodyEnd).toString())
		const handler = handlers[message.method]
		if (handler) {
			const result = handler(message.params)
			if ('id' in message) respond(message.id, result)
		}
		buffer = buffer.subarray(bodyEnd)
	}
})
