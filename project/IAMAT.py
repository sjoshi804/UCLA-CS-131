import asyncio
from time import time

HOST = "127.0.0.1"
GOLOMAN = "Goloman"
HANDS = "Hands"
HOLIDAY = "Holiday"
WILKES = "Wilkes"
WELSH = "Welsh"
SERVERS = {GOLOMAN, HANDS, HOLIDAY, WILKES, WELSH}
SERVER_PORTS = {GOLOMAN: 11958, HANDS: 11959, HOLIDAY: 11960, WILKES: 11961, WELSH: 11962}
async def main():
    for server in SERVERS:
        reader, writer = await asyncio.open_connection(HOST, SERVER_PORTS[server])
        writer.write(("IAMAT " + server + ".cs.ucla.edu +34.068930-118.445127 " + str(time()) + "\n").encode())
        data = await reader.readline()
        print('Received: {}'.format(data.decode()))
        writer.close()
    
if __name__ == '__main__':
    asyncio.run(main())