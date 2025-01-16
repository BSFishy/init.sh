import scriptContent from '../init.sh';
import pageContent from './index.html';

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
			message = pageContent;
		}

		return new Response(message, {
			status: 200,
			headers: {
				'Content-Type': isCurl ? 'text/plain' : 'text/html',
			},
		});
	},
};
