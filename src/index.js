/** @type {string} */
import scriptContent from '../init.sh';

/**
 * @param {string} str
 * @returns {string}
 */
function dedent(str) {
	let indent = Infinity;
	const lines = str.split('\n');
	for (const line of lines) {
		if (/^\W*$/m.test(line)) {
			continue;
		}

		const match = /^\W*/m.exec(line);
		if (!match) {
			continue;
		}

		indent = Math.min(indent, match[0].length);
	}

	return lines.map((line) => line.substring(indent)).join('\n');
}

export default {
	/**
	 * Handles the incoming request and determines if it's from curl.
	 * @param {Request} request - The incoming request object.
	 * @returns {Promise<Response>} - A response indicating if the request is from curl.
	 */
	async fetch(request) {
		const userAgent = request.headers.get('User-Agent') || '';
		const isCurl = userAgent.toLowerCase().includes('curl');

		/** @type {string} */
		let message;
		if (isCurl) {
			message = scriptContent;
		} else {
			message = dedent(`
				If on Ubuntu, make sure curl is installed:

				sudo apt update && sudo apt install -yq curl

				To install, run:

				bash <(curl -L https://init.mattprovost.dev)
			`);
		}

		return new Response(message, {
			status: 200,
			headers: {
				'Content-Type': 'text/plain',
			},
		});
	},
};
