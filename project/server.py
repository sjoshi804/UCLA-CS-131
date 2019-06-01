import asyncio
import aiohttp
import logging
import sys

HOST = "127.0.0.1"
GOLOMAN = "Goloman"
HANDS = "Hands"
HOLIDAY = "Holiday"
WILKES = "Wilkes"
WELSH = "Welsh"
SERVER_PORTS = {GOLOMAN: 11958, HANDS: 11959, HOLIDAY: 11960, WILKES: 11961, WELSH: 11961}
SERVER_LINKS = {GOLOMAN: [HANDS, HOLIDAY, WILKES], HANDS: [GOLOMAN, WILKES], HOLIDAY: [GOLOMAN, WILKES, WELSH], WILKES: [GOLOMAN, HANDS, HOLIDAY], WELSH: [HOLIDAY]}
CLIENTS_LOCATION_DB = {}
async def main():
    #Check if called with correct arguments
    if (len(sys.argv) != 2):
        print("Usage: server.py [server name]")
        exit(code=1)
    elif (not (sys.argv[1] in SERVER_PORTS)):
        print("Invalid server \n. Please choose a server from one of the following: Goloman, Hands, Holiday, Wilkes, Welsh")
        exit(code=1)
    else:
        print("Starting " + sys.argv[1])
        server = await asyncio.start_server(handle_connection, host='127.0.0.1', port=SERVER_PORTS[sys.argv[1]])
        await server.serve_forever()
        exit(code=0)

async def handle_connection(reader, writer):
    data = await reader.readline()
    message = data.decode().split()
    if (message[0] == "IAMAT"):
        # Store client location
        CLIENTS_LOCATION_DB[message[1]] = (message[3], message[4])
        
        # Reply to client with AT message
        reply = "AT " + sys.argv[1] + message[1] + message[2] + message[3] + message[4] + "\n"
        writer.write(reply.encode())

        # Flood message to all servers excluding sender (to prevent infinite loop)
        

    elif (message[0] == "WHATSAT"):
        #Make call to Google Places API
        reply = "AT " + sys.argv[1] + "\n"
        writer.write(reply.encode())
    else:
        reply = "Invalid command.\n"
        writer.write(reply.encode())
    await writer.drain()
    writer.close()

if __name__ == '__main__':
    asyncio.run(main())