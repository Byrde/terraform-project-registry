import {
	ICredentialTestRequest,
	ICredentialType,
	INodeProperties,
} from 'n8n-workflow';

export class IBKRApi implements ICredentialType {
	name = 'ibkrApi';
	displayName = 'IBKR API';
	documentationUrl = 'https://www.interactivebrokers.com/en/trading/ib-api.php';
	properties: INodeProperties[] = [
		{
			displayName: 'Base URL',
			name: 'baseUrl',
			type: 'string',
			default: 'http://localhost:4001/v1/api',
			description: 'IB Gateway API base URL. Default is http://localhost:4001/v1/api for paper trading. Use http://localhost:7497/v1/api for live trading.',
			required: true,
		},
		{
			displayName: 'Account ID',
			name: 'accountId',
			type: 'string',
			default: '',
			description: 'Your Interactive Brokers account ID',
			required: true,
		},
	];

	test: ICredentialTestRequest = {
		request: {
			baseURL: '={{$credentials.baseUrl}}',
			url: '/iserver/auth/status',
		},
	};
}

