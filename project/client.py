#TODO: Add more test cases - for valid command checking etc.

import asyncio
from time import time

HOST = "127.0.0.1"
GOLOMAN = "Goloman"
HANDS = "Hands"
HOLIDAY = "Holiday"
WILKES = "Wilkes"
WELSH = "Welsh"
SERVER_PORTS = {GOLOMAN: 11958, HANDS: 11959, HOLIDAY: 11960, WILKES: 11961, WELSH: 11962}
async def main():
    reader, writer = await asyncio.open_connection(HOST, SERVER_PORTS[GOLOMAN])
    writer.write(("IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 " + str(time()) + "\n").encode())
    data = await reader.readline()
    print('Received: {}'.format(data.decode()))
    writer.close()
    reader2, writer2 = await asyncio.open_connection(HOST, SERVER_PORTS[WELSH])
    writer2.write(("WHATSAT kiwi.cs.ucla.edu 10 5\n").encode())
    data = await reader2.readline()
    print('Received: {}'.format(data.decode()))
    writer2.close()
if __name__ == '__main__':
    asyncio.run(main())