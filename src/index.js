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
			const result = await fetch('https://raw.githubusercontent.com/BSFishy/init.sh/refs/heads/main/init.sh');
			if (!result.ok) {
				return new Response('failed to fetch script', {
					status: 500,
					headers: {
						'Content-Type': 'text/plain',
					},
				});
			}

			message = await result.text();
		} else {
			message = `To install, run:\n\nsh <(curl -L https://init.mattprovost.dev)`;
		}

		return new Response(message, {
			status: 200,
			headers: {
				'Content-Type': 'text/plain',
			},
		});
	},
};
