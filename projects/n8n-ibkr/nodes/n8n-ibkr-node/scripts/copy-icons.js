#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function copyIcons() {
	const sourceDir = path.join(__dirname, '../nodes');
	const destDir = path.join(__dirname, '../dist/nodes');

	function copyRecursive(src, dest) {
		const entries = fs.readdirSync(src, { withFileTypes: true });

		for (const entry of entries) {
			const srcPath = path.join(src, entry.name);
			const destPath = path.join(dest, entry.name);

			if (entry.isDirectory()) {
				if (!fs.existsSync(destPath)) {
					fs.mkdirSync(destPath, { recursive: true });
				}
				copyRecursive(srcPath, destPath);
			} else if (entry.isFile() && /\.(png|svg)$/i.test(entry.name)) {
				if (!fs.existsSync(path.dirname(destPath))) {
					fs.mkdirSync(path.dirname(destPath), { recursive: true });
				}
				fs.copyFileSync(srcPath, destPath);
				console.log(`Copied: ${srcPath} -> ${destPath}`);
			}
		}
	}

	if (!fs.existsSync(sourceDir)) {
		console.warn(`Source directory does not exist: ${sourceDir}`);
		return;
	}

	if (!fs.existsSync(destDir)) {
		fs.mkdirSync(destDir, { recursive: true });
	}

	copyRecursive(sourceDir, destDir);
	console.log('Icons copied successfully');
}

copyIcons();

