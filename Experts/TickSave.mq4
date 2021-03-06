//+------------------------------------------------------------------+
//|                                                     TickSave.mq4 |
//|                                      Copyright © 2006, komposter |
//|                                      mailto:komposterius@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, komposter"
#property link      "mailto:komposterius@mail.ru"

extern string	SymbolList		= "EURUSD,.DE30Cash";
extern bool		WriteWarnings	= false;

string SymbolsArray[32], strComment; double preBid[32];
int FileHandle[32], SymbolsCount = 0;

#define strEXPERT_WAS_STOPED  "--------------------------Expert was stoped"
#define strCONNECTION_LOST    "--------------------------Connection lost  "
#define strLEN						45

bool preIsConnected = true, nowIsConnected = true;

int init() { start(); return(0); }
int start()
{
	string ServerName = AccountServer();
	int CurYear = Year();
	int CurMonth = Month();
	int CurDay = Day();

	// Èçâëåêàåì èç ñòðîêè SymbolList ñïèñîê ñèìâîëîâ
	if ( !PrepareSymbolList() ) { return(-1); }

	// Ïðîâåðÿåì ñîñòîÿíèå ñîåäèíåíèÿ
	if ( !ConnectionCheck() ) { return(-1); }

	// Îòêðûâàåì ôàéëû
	if ( !OpenFiles() ) { return(-1); }

	while ( !IsStopped() )
	{
		// Åñëè ïîìåíÿëñÿ ñåðâåð, ñðàçó ïðåêðàùàåì çàïèñü - äëÿ íîâîãî ñåðâåðà áóäåò ñîçäàíà ñâîÿ ïàïêà
		if ( ServerName != AccountServer()  ) { break; }

		// Åñëè ïîìåíÿëñÿ ìåñÿö, ñðàçó ïðåêðàùàåì çàïèñü - äëÿ íîâîãî ìåñÿöà áóäåò ñîçäàí ñâîé ôàéë
		if ( CurYear != Year() ) { break; }
		if ( CurMonth != Month() ) { break; }
		if ( CurDay != Day()) {break;}

		// Åñëè ïðîïàëà ñâÿçü,
		if ( !IsConnected() )
		{
			// çàïèñûâàåì ïðåäóïðåæäåíèå âî âñå ôàéëû
			WriteConnectionLost();
			preIsConnected = false;
		}
		// Åñëè ñâÿçü åñòü,
		else
		{
			// Çàïèñûâàåì ïîñòóïèâøèå òèêè
			WriteTick();
			preIsConnected = true;
		}
		Sleep(100);
	}

	// Çàêðûâàåì ôàéëû
	CloseFiles();

	Comment("");

	return(0);
}

//+------------------------------------------------------------------+
//| Èçâëåêàåì èç ñòðîêè SymbolList ñïèñîê ñèìâîëîâ
//+------------------------------------------------------------------+
bool PrepareSymbolList()
{
	int		curchar = 0, len = StringLen( SymbolList ), curSymbol;
	string	cur_symbol = ""; SymbolsCount = 0;

	//---- óñòàíàâëèâàåì óìîë÷àòåëüíûé ðàçìåð ìàññèâà ñèìâîëîâ
	ArrayResize( SymbolsArray, 32 );

	//---- ïåðåáèðàåì âñå ñèìâîëû â ñïèñêå ãðàôèêîâ
	for ( int pos = 0; pos <= len; pos ++ )
	{
		curchar = StringGetChar( SymbolList, pos );
		//---- åñëè òåêóùèé ñèìâîë - íå çàïÿòàÿ è íå ïîñëåäíèé ñèìâîë â ñòðîêå,
		if ( curchar != ',' && pos != len )
		{
			//---- ýòî - îäèí èç ñèìâîëîâ èíñòðóìåíòà ãðàôèêà
			cur_symbol = cur_symbol + CharToStr( curchar );
			continue;
		}
		//---- åñëè òåêóùèé ñèìâîë çàïÿòàÿ, èëè ýòî - ïîñëåäíèé ñèìâîë â ñòðîêå,
		else
		{ 
			//---- çíà÷èò, â ïåðåìåííîé cur_symbol - ïîëíîå èìÿ ñèìâîëà. Ïðîâåðÿåì åãî:
			MarketInfo( cur_symbol, MODE_BID );
			if ( GetLastError() == 4106 )
			{
				Alert( "Íåèçâåñòíûé ñèìâîë ", cur_symbol, "!!!" );
				return(false);
			}

			//---- åñëè ñèìâîë ðåàëüíî ñóùåñòâóåò, ïðîâåðÿåì, íåò ëè òàêîãî ñèìîëà â íàøåì ñïèñêå:
			bool Uniq = true;
			for ( curSymbol = 0; curSymbol < SymbolsCount; curSymbol ++ )
			{
				if ( cur_symbol == SymbolsArray[curSymbol] )
				{
					Uniq = false;
					break;
				}
			}

			//---- åñëè òàêîãî ñèìîëà â íàøåì ñïèñêå íåò, çàïèñûâàåì åãî, è ñ÷èòàåì îáùåå êîëè÷åñòâî:
			if ( Uniq )
			{
				SymbolsArray[SymbolsCount] = cur_symbol;
				SymbolsCount ++;
				if ( SymbolsCount > 31 )
				{
					Alert( "Ñëèøêîì ìíîãî ñèìâîëîâ! Îòêðûòü ìîæíî ìàêñèìóì 32 ôàéëà!" );
					return(false);
				}
			}

			//---- îáíóëÿåì çíà÷åíèå ïåðåìåííîé
			cur_symbol = "";
		}
	}

	//---- åñëè íè îäèí ñèìâîë íå áûë íàéäåí, âûõîäèì
	if ( SymbolsCount <= 0 )
	{
		Alert( "Íå îïðåäåëåíî íè îäíîãî ñèìâîëà!!!" );
		return(false);
	}
	
	//---- óñòàíàâëèâàåì ðàçìåð âñåõ ìàññèâîâ ïîä êîë-âî ñèìâîëîâ:
	ArrayResize		( SymbolsArray	, SymbolsCount );
	ArrayResize		( preBid			, SymbolsCount );
	ArrayInitialize( preBid			, -1 				);
	ArrayResize		( FileHandle	, SymbolsCount );
	ArrayInitialize( FileHandle	, -1 				);

	//---- Âûâîäèì èíôîðìàöèþ:
	string uniq_symbols_list = SymbolsArray[0];
	for ( curSymbol = 1; curSymbol < SymbolsCount; curSymbol ++ )
	{
		if ( curSymbol == SymbolsCount - 1 )
		{ uniq_symbols_list = uniq_symbols_list + " è " + SymbolsArray[curSymbol]; }
		else
		{ uniq_symbols_list = uniq_symbols_list + ", " + SymbolsArray[curSymbol]; }
	}
	strComment = StringConcatenate( AccountServer(), ": îáðàáàòûâàåòñÿ ", SymbolsCount, " ñèìâîë(-à,-îâ):\n", uniq_symbols_list, "\n" );
	Comment( strComment );

	return(true);
}

//+------------------------------------------------------------------+
//| Ïðîâåðÿåì ñîñòîÿíèå ñîåäèíåíèÿ
//+------------------------------------------------------------------+
bool ConnectionCheck()
{
	while ( !IsConnected() )
	{
		Comment( AccountServer(), ": ÍÅÒ ÑÂßÇÈ Ñ ÑÅÐÂÅÐÎÌ!!!" );
		if ( IsStopped() ) { return(false); }
		Sleep(100);
	}
	return(true);
}

//+------------------------------------------------------------------+
//| Îòêðûâàåì ôàéëû, â êîòîðûå áóäåì çàïèñûâàòü òèêè
//+------------------------------------------------------------------+
bool OpenFiles()
{
	int _GetLastError;
	for ( int curSymbol = 0; curSymbol < SymbolsCount; curSymbol ++ )
	{
		string FileName = StringConcatenate( "[Ticks]\\", AccountServer(), "\\", SymbolsArray[curSymbol], "_", Year(), ".", strMonth(),".",strDay(), ".csv" );
		FileHandle[curSymbol] = FileOpen( FileName, FILE_READ | FILE_WRITE );

		if ( FileHandle[curSymbol] < 0 )
		{
			_GetLastError = GetLastError();
			Alert( "FileOpen( " + FileName + ", FILE_READ | FILE_WRITE ) - Error #", _GetLastError );
			return(false);
		}

		if ( !FileSeek( FileHandle[curSymbol], 0, SEEK_END ) )
		{
			_GetLastError = GetLastError();
			Alert( "FileSeek( " + FileHandle[curSymbol] + ", 0, SEEK_END ) - Error #", _GetLastError );
			return(false);
		}

		if ( WriteWarnings )
		{
			if ( FileWrite( FileHandle[curSymbol], strEXPERT_WAS_STOPED ) < 0 )
			{
				_GetLastError = GetLastError();
				Alert( "Ticks(" + Symbol() + ") - FileWrite() Error #", _GetLastError );
				return(false);
			}
			FileFlush( FileHandle[curSymbol] );
		}

		preBid[curSymbol] = MarketInfo( SymbolsArray[curSymbol], MODE_BID );
	}
	return(true);
}

//+------------------------------------------------------------------+
//| Åñëè ïðîïàëà ñâÿçü, çàïèñûâàåì ïðåäóïðåæäåíèå âî âñå ôàéëû
//+------------------------------------------------------------------+
void WriteConnectionLost()
{
	int _GetLastError;

	if ( !preIsConnected ) { return(0); }
	
	Comment( strComment, "ÍÅÒ ÑÂßÇÈ Ñ ÑÅÐÂÅÐÎÌ!!!" );

	if ( !WriteWarnings ) { return(0); }

	for ( int curSymbol = 0; curSymbol < SymbolsCount; curSymbol ++ )
	{
		if ( FileHandle[curSymbol] < 0 ) { continue; }

		if ( !FileSeek( FileHandle[curSymbol], -strLEN, SEEK_END ) )
		{
			_GetLastError = GetLastError();
			Alert( "FileSeek( " + FileHandle[curSymbol] + ", -strLEN, SEEK_END ) - Error #", _GetLastError );
			continue;
		}

		if ( FileWrite( FileHandle[curSymbol], strCONNECTION_LOST ) < 0 )
		{
			_GetLastError = GetLastError();
			Alert( "FileWrite() Error #", _GetLastError );
		}

		if ( FileWrite( FileHandle[curSymbol], strEXPERT_WAS_STOPED ) < 0 )
		{
			_GetLastError = GetLastError();
			Alert( "FileWrite() Error #", _GetLastError );
		}

		FileFlush( FileHandle[curSymbol] );
	}
}

//+------------------------------------------------------------------+
//| Çàïèñûâàåì ïîñòóïèâøèå òèêè
//+------------------------------------------------------------------+
void WriteTick()
{
	int _GetLastError; double curBid; double curAsk; int curDigits;
	Comment( strComment );
	for ( int curSymbol = 0; curSymbol < SymbolsCount; curSymbol ++ )
	{
		if ( FileHandle[curSymbol] < 0 ) { continue; }

		curBid = MarketInfo( SymbolsArray[curSymbol], MODE_BID );
		curAsk = MarketInfo( SymbolsArray[curSymbol], MODE_ASK );
		curDigits = MarketInfo( SymbolsArray[curSymbol], MODE_DIGITS );

		if ( 	NormalizeDouble( curBid - preBid[curSymbol], curDigits ) < 0.00000001 && 
				NormalizeDouble( preBid[curSymbol] - curBid, curDigits ) < 0.00000001 ) { continue; }

		preBid[curSymbol] = curBid;

		if ( WriteWarnings )
		{
			if ( !FileSeek( FileHandle[curSymbol], -strLEN, SEEK_END ) )
			{
				_GetLastError = GetLastError();
				Alert( "FileSeek( " + FileHandle[curSymbol] + ", -strLEN, SEEK_END ) - Error #", _GetLastError );
				continue;
			}
		}
		else
		{
			if ( !FileSeek( FileHandle[curSymbol], 0, SEEK_END ) )
			{
				_GetLastError = GetLastError();
				Alert( "FileSeek( " + FileHandle[curSymbol] + ", 0, SEEK_END ) - Error #", _GetLastError );
				continue;
			}
		}

		if ( FileWrite( FileHandle[curSymbol], TimeToStr( TimeLocal(), TIME_DATE | TIME_SECONDS ), DoubleToStr( curBid, curDigits ), DoubleToStr( curAsk, curDigits ) ) < 0 )
		{
			_GetLastError = GetLastError();
			Alert( "FileWrite() Error #", _GetLastError );
		}

		if ( WriteWarnings )
		{
			if ( FileWrite ( FileHandle[curSymbol], strEXPERT_WAS_STOPED ) < 0 )
			{
				_GetLastError = GetLastError();
				Alert( "FileWrite() Error #", _GetLastError );
			}
		}

		FileFlush( FileHandle[curSymbol] );
	}
}

//+------------------------------------------------------------------+
//| Çàêðûâàåì âñå ôàéëû
//+------------------------------------------------------------------+
void CloseFiles()
{
	for ( int curSymbol = 0; curSymbol < SymbolsCount; curSymbol ++ )
	{
		if ( FileHandle[curSymbol] > 0 )
		{
			FileClose( FileHandle[curSymbol] );
			FileHandle[curSymbol] = -1;
		}
	}
}

string strMonth()
{
	if ( Month() < 10 ) return( StringConcatenate( "0", Month() ) );
	return(Month());
}

string strDay() 
{
	if ( Day() < 10 ) return( StringConcatenate( "0", Day() ) );
	return(Day());

}