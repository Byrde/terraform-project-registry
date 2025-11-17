# n8n IBKR Node

Custom n8n node for integrating with Interactive Brokers (IBKR) API. This node allows you to interact with your IBKR account directly from n8n workflows.

## Features

- **Health Check**: Verify that the IBKR API is accessible and healthy
- **List Positions**: Retrieve current positions in your IBKR account
- **Buy Stock**: Place buy orders for stocks
- **Sell Stock**: Place sell orders for stocks

**Note**: This node is automatically installed when deploying the n8n-ibkr Terraform module. No manual installation required.

## Configuration

### Credentials

This node is designed to work with IB Gateway running as a sidecar container in the same Cloud Run service as n8n. Both containers share the same network namespace, allowing connections via `localhost`.

**Required Credentials**:

1. **Base URL**: The IB Gateway API base URL
   - Paper trading: `http://localhost:4001/v1/api` (default)
   - Live trading: `http://localhost:7497/v1/api`
   - The port matches the `ib_gateway_container_port` configured in your Terraform deployment

2. **Account ID**: Your Interactive Brokers account ID

**Note**: IB Gateway handles authentication internally when the container starts. The Gateway is already authenticated using credentials stored in Google Secret Manager (configured via Terraform variables `ib_gateway_tws_userid` and `ib_gateway_tws_password`). This node connects to the authenticated Gateway instance via localhost.

## Operations

### Health Check

Checks if the IBKR API is accessible and returns the API status.

**Output**: Returns status information including:
- `status`: "healthy" or "unhealthy"
- `statusCode`: HTTP status code
- `timestamp`: Current timestamp

### List Positions

Retrieves all current positions in your IBKR account.

**Output**: Returns an array of position objects with details such as:
- Symbol
- Quantity
- Average cost
- Current market value
- Unrealized P&L

### Buy Stock

Places a buy order for a stock.

**Required Parameters**:
- **Symbol**: Stock symbol (e.g., AAPL, MSFT)
- **Quantity**: Number of shares to buy
- **Order Type**: Market, Limit, Stop, or Stop Limit
- **Time in Force**: Day, GTC, IOC, or FOK

**Optional Parameters** (depending on order type):
- **Limit Price**: Required for Limit and Stop Limit orders
- **Stop Price**: Required for Stop and Stop Limit orders

**Output**: Returns order confirmation with order ID and status.

### Sell Stock

Places a sell order for a stock.

**Required Parameters**:
- **Symbol**: Stock symbol (e.g., AAPL, MSFT)
- **Quantity**: Number of shares to sell
- **Order Type**: Market, Limit, Stop, or Stop Limit
- **Time in Force**: Day, GTC, IOC, or FOK

**Optional Parameters** (depending on order type):
- **Limit Price**: Required for Limit and Stop Limit orders
- **Stop Price**: Required for Stop and Stop Limit orders

**Output**: Returns order confirmation with order ID and status.

## Order Types

- **Market (MKT)**: Order executed at the current market price
- **Limit (LMT)**: Order executed at a specified price or better
- **Stop (STP)**: Order becomes a market order when stop price is reached
- **Stop Limit (STP LMT)**: Order becomes a limit order when stop price is reached

## Time in Force Options

- **DAY**: Order is valid for the trading day
- **GTC**: Good Till Cancel - order remains active until filled or cancelled
- **IOC**: Immediate or Cancel - order must be filled immediately or cancelled
- **FOK**: Fill or Kill - order must be filled completely or cancelled

## Example Workflows

### Check API Health and List Positions

1. Add an IBKR node with operation "Health Check"
2. Add another IBKR node with operation "List Positions"
3. Connect them in sequence

### Automated Stock Purchase

1. Add a trigger node (e.g., Schedule Trigger)
2. Add an IBKR node with operation "Buy Stock"
3. Configure:
   - Symbol: `AAPL`
   - Quantity: `10`
   - Order Type: `Market`
   - Time in Force: `DAY`

## Error Handling

The node includes error handling and will:
- Return error information in the output if "Continue on Fail" is enabled
- Throw errors if "Continue on Fail" is disabled (default)

## Security Notes

- IB Gateway runs as a sidecar container and is only accessible from within the Cloud Run service via `localhost`
- Gateway authentication credentials are stored securely in Google Secret Manager (managed by Terraform)
- The node connects to the already-authenticated Gateway instance - no additional API keys needed
- Never expose IB Gateway externally - it should only be accessible via localhost within the Cloud Run service
- Account ID is stored in n8n credentials (encrypted at rest)

## Troubleshooting

### Authentication Errors

- Verify IB Gateway container is running and authenticated
- Check Cloud Run logs for the `ib-gateway` container to see authentication status
- Ensure the account ID matches your IBKR account
- Verify IB Gateway has completed 2FA authentication (check IB Key mobile app)
- Confirm the Gateway container port matches your Base URL configuration

### Order Execution Errors

- Verify you have sufficient buying power for buy orders
- Check that you have the stock position for sell orders
- Ensure the symbol is correct and tradeable
- Verify market hours if placing orders outside trading hours

### Connection Errors

- Verify IB Gateway sidecar container is running in the same Cloud Run service
- Check that the Base URL uses `localhost` (not an external URL)
- Ensure the port matches your Terraform `ib_gateway_container_port` setting
- Verify both n8n and IB Gateway containers are in the same Cloud Run service
- Check Cloud Run logs for connection errors
- Ensure the Gateway container has successfully started and authenticated

## API Documentation

For detailed API documentation, refer to:
- [Interactive Brokers API Documentation](https://www.interactivebrokers.com/en/trading/ib-api.php)

## License

MIT

