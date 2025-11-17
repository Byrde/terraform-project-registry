import {
	IExecuteFunctions,
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
	NodePropertyTypes,
} from 'n8n-workflow';

export class IBKR implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'IBKR',
		name: 'ibkr',
		icon: 'file:ibkr.svg',
		group: ['transform'],
		version: 1,
		subtitle: '={{$parameter["operation"]}}',
		description: 'Interact with Interactive Brokers API',
		defaults: {
			name: 'IBKR',
		},
		inputs: ['main'],
		outputs: ['main'],
		credentials: [
			{
				name: 'ibkrApi',
				required: true,
			},
		],
		properties: [
			{
				displayName: 'Operation',
				name: 'operation',
				type: 'options',
				noDataExpression: true,
				options: [
					{
						name: 'Health Check',
						value: 'healthCheck',
						description: 'Check if the IBKR API is accessible and healthy',
						action: 'Check API health',
					},
					{
						name: 'List Positions',
						value: 'listPositions',
						description: 'Get current positions in the account',
						action: 'List current positions',
					},
					{
						name: 'Buy Stock',
						value: 'buyStock',
						description: 'Place a buy order for a stock',
						action: 'Buy a stock',
					},
					{
						name: 'Sell Stock',
						value: 'sellStock',
						description: 'Place a sell order for a stock',
						action: 'Sell a stock',
					},
				],
				default: 'healthCheck',
			},
			{
				displayName: 'Symbol',
				name: 'symbol',
				type: 'string',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
					},
				},
				default: '',
				required: true,
				description: 'Stock symbol (e.g., AAPL, MSFT)',
			},
			{
				displayName: 'Quantity',
				name: 'quantity',
				type: 'number',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
					},
				},
				default: 1,
				required: true,
				description: 'Number of shares to buy or sell',
			},
			{
				displayName: 'Order Type',
				name: 'orderType',
				type: 'options',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
					},
				},
				options: [
					{
						name: 'Market',
						value: 'MKT',
					},
					{
						name: 'Limit',
						value: 'LMT',
					},
					{
						name: 'Stop',
						value: 'STP',
					},
					{
						name: 'Stop Limit',
						value: 'STP LMT',
					},
				],
				default: 'MKT',
				description: 'Type of order to place',
			},
			{
				displayName: 'Limit Price',
				name: 'limitPrice',
				type: 'number',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
						orderType: ['LMT', 'STP LMT'],
					},
				},
				default: 0,
				description: 'Limit price for limit orders',
			},
			{
				displayName: 'Stop Price',
				name: 'stopPrice',
				type: 'number',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
						orderType: ['STP', 'STP LMT'],
					},
				},
				default: 0,
				description: 'Stop price for stop orders',
			},
			{
				displayName: 'Time in Force',
				name: 'timeInForce',
				type: 'options',
				displayOptions: {
					show: {
						operation: ['buyStock', 'sellStock'],
					},
				},
				options: [
					{
						name: 'Day',
						value: 'DAY',
					},
					{
						name: 'Good Till Cancel',
						value: 'GTC',
					},
					{
						name: 'Immediate or Cancel',
						value: 'IOC',
					},
					{
						name: 'Fill or Kill',
						value: 'FOK',
					},
				],
				default: 'DAY',
				description: 'Time in force for the order',
			},
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];
		const operation = this.getNodeParameter('operation', 0) as string;

		const credentials = await this.getCredentials('ibkrApi');
		const baseUrl = (credentials.baseUrl as string).replace(/\/$/, ''); // Remove trailing slash
		const accountId = credentials.accountId as string;

		for (let i = 0; i < items.length; i++) {
			try {
				let responseData;

				switch (operation) {
					case 'healthCheck':
						responseData = await this.healthCheck(baseUrl, this);
						break;
					case 'listPositions':
						responseData = await this.listPositions(baseUrl, accountId, this);
						break;
					case 'buyStock':
						responseData = await this.placeOrder(
							baseUrl,
							accountId,
							'BUY',
							this.getNodeParameter('symbol', i) as string,
							this.getNodeParameter('quantity', i) as number,
							this.getNodeParameter('orderType', i) as string,
							this.getNodeParameter('limitPrice', i) as number,
							this.getNodeParameter('stopPrice', i) as number,
							this.getNodeParameter('timeInForce', i) as string,
							this
						);
						break;
					case 'sellStock':
						responseData = await this.placeOrder(
							baseUrl,
							accountId,
							'SELL',
							this.getNodeParameter('symbol', i) as string,
							this.getNodeParameter('quantity', i) as number,
							this.getNodeParameter('orderType', i) as string,
							this.getNodeParameter('limitPrice', i) as number,
							this.getNodeParameter('stopPrice', i) as number,
							this.getNodeParameter('timeInForce', i) as string,
							this
						);
						break;
					default:
						throw new Error(`Unknown operation: ${operation}`);
				}

				returnData.push({
					json: responseData,
					pairedItem: {
						item: i,
					},
				});
			} catch (error) {
				if (this.continueOnFail()) {
					returnData.push({
						json: {
							error: error instanceof Error ? error.message : String(error),
						},
						pairedItem: {
							item: i,
						},
					});
					continue;
				}
				throw error;
			}
		}

		return [returnData];
	}

	private async healthCheck(baseUrl: string, executeFunctions: IExecuteFunctions): Promise<any> {
		try {
			const response = await executeFunctions.helpers.request({
				method: 'GET',
				url: `${baseUrl}/iserver/auth/status`,
				returnFullResponse: true,
			});

			return {
				status: response.statusCode === 200 ? 'healthy' : 'unhealthy',
				statusCode: response.statusCode,
				timestamp: new Date().toISOString(),
				authenticated: response.statusCode === 200,
			};
		} catch (error) {
			return {
				status: 'unhealthy',
				error: error instanceof Error ? error.message : String(error),
				timestamp: new Date().toISOString(),
				authenticated: false,
			};
		}
	}

	private async listPositions(baseUrl: string, accountId: string, executeFunctions: IExecuteFunctions): Promise<any> {
		const response = await executeFunctions.helpers.request({
			method: 'GET',
			url: `${baseUrl}/portfolio/${accountId}/positions`,
		});

		if (Array.isArray(response)) {
			return {
				positions: response,
				count: response.length,
			};
		}

		return response;
	}

	private async placeOrder(
		baseUrl: string,
		accountId: string,
		side: 'BUY' | 'SELL',
		symbol: string,
		quantity: number,
		orderType: string,
		limitPrice: number,
		stopPrice: number,
		timeInForce: string,
		executeFunctions: IExecuteFunctions
	): Promise<any> {
		const conid = await this.getConid(baseUrl, symbol, executeFunctions);

		const order: any = {
			conid: conid,
			orderType: orderType,
			side: side,
			quantity: quantity,
			tif: timeInForce,
		};

		if (orderType === 'LMT' || orderType === 'STP LMT') {
			if (!limitPrice || limitPrice <= 0) {
				throw new Error('Limit price is required for limit orders');
			}
			order.price = limitPrice;
		}

		if (orderType === 'STP' || orderType === 'STP LMT') {
			if (!stopPrice || stopPrice <= 0) {
				throw new Error('Stop price is required for stop orders');
			}
			order.auxPrice = stopPrice;
		}

		const response = await executeFunctions.helpers.request({
			method: 'POST',
			url: `${baseUrl}/iserver/account/${accountId}/orders`,
			body: {
				orders: [order],
			},
			json: true,
		});

		return {
			orderId: response.id || response.orderId,
			status: response.status || 'submitted',
			symbol: symbol,
			side: side,
			quantity: quantity,
			orderType: orderType,
			...response,
		};
	}

	private async getConid(baseUrl: string, symbol: string, executeFunctions: IExecuteFunctions): Promise<number> {
		const response = await executeFunctions.helpers.request({
			method: 'GET',
			url: `${baseUrl}/iserver/secdef/search`,
			qs: {
				symbol: symbol,
				name: true,
				secType: 'STK',
			},
		});

		if (Array.isArray(response) && response.length > 0) {
			return response[0].conid;
		}

		if (response && response.conid) {
			return response.conid;
		}

		throw new Error(`Could not find contract ID for symbol: ${symbol}. Please verify the symbol is correct.`);
	}
}

