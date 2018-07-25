pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract EventStructContract {
        //структура для хранения события
        struct EventStruct {
          uint64 eventID;    
          uint eventDate;
          uint8 result; // 0 - отрицательный, 1 - положительный, 2 - не выставлен
          uint resultSetTime; // время, когда админ выставил результат события 
          bool isSet;
          uint8 percent; //процент, оставляемый за владельцем контракта
          uint minBet;
          uint maxBet;
          
        }   
}


contract EventsDatabase is Ownable, EventStructContract {


    
    //Событие. Записываем лог
    event createEventLog(string _description, uint _eventDate,  uint64 _eventID );
    event setEventResultLog(string _description,  uint64 _eventID, uint8 _result );
    event editEventResultLog(string _description,  uint64 _eventID, uint8 _result );

    //адресс с которого разрешено заносить события в базу
    address manager;
    
    //Сама база данных ID события => структура
    mapping (uint64 => EventStruct) public eventDatabase;
    
    //конструктор. Вызывается 1 раз при деплое контракта
    constructor() public {
        manager = msg.sender;
    }

    //Модификатор проверяющий, является ли вызвавший метод владельцем контракта или менеджером
    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager));
        _;
    }

    //Смена менеджера. Может быть вызвана только владельцем
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }
    
    //Заносим событие в базу данных
    function createEvent(string _description, uint _eventDate, uint8 _percent, uint _minBet, uint _maxBet , uint64 _eventID ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(eventDatabase[_eventID].isSet){
            revert();
        }
        EventStruct memory eventStruct = EventStruct({eventID:_eventID, eventDate:_eventDate, result:2, resultSetTime:0, isSet:true, percent:_percent, minBet:_minBet, maxBet:_maxBet });
        
        eventDatabase[_eventID] = eventStruct;
        emit createEventLog(_description,  _eventDate,   _eventID);
    }
    
    function setEventResult(string _description, uint64 _eventID, uint8 _result  ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        //проверяем - наступилали дата события
        if(now < eventDatabase[_eventID].eventDate){
            revert();
        }
        //проверяем - выставлен ли результат
        if(eventDatabase[_eventID].result!=2){
            revert();
        }
        
        eventDatabase[_eventID].result = _result;
        eventDatabase[_eventID].resultSetTime = now;
        emit setEventResultLog(_description,  _eventID,   _result);
    }
    
    function editEventResult(string _description, uint64 _eventID, uint8 _result  ) public onlyOwner {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        //проверяем - наступилали дата события
        if(now < eventDatabase[_eventID].eventDate){
            revert();
        }
        //проверяем, не прошлили 24 часа с момента установки результата события админом
        if(now > (eventDatabase[_eventID].resultSetTime + 24*60*60)){
            revert();
        }
        
        
        eventDatabase[_eventID].result = _result;
        emit editEventResultLog(_description,  _eventID,   _result);
    }
    
    function getEventResult( uint64 _eventID ) public constant returns(uint8) {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        
        return eventDatabase[_eventID].result;
    }
    
    
    function readEventFromDatabase (uint64 _eventID) public constant returns (EventStruct) {
        return eventDatabase[_eventID];
    }
    
}



contract BetContract is Ownable, EventStructContract {

    //Контракт со списком событий
    EventsDatabase public eventsDatabase;
    //uint public bettorTakeRewardsPeriod = 60*60; // период, в течении которого Беттор может забрать выигрыш
    //uint public bookmakerTakeRewardsPeriod = 60*60; // период, в течении которого Букмэйкер может забрать выигрыш
    uint public takeRewardsPeriod = 60*60; // период, в течении которого может забрать выигрыш
    uint64 public currBetID = 0;
    

    //структура ставкт
    struct BetStruct {
      uint64 betID;
      uint64 eventID; 
      address bettor;
      address bookmaker;
      uint rate; // 1000000000000000000 - это 1
      uint bettorValue;
      uint bookmakerValue;
      //uint bettorTakeRewardsPeriod; // период, в течении которого Беттор может забрать выигрыш
      //uint bookmakerTakeRewardsPeriod; // период, в течении которого Букмэйкер может забрать выигрыш
      uint takeRewardsPeriod;
      bool isSet;
      bool isPaid;
    }
    
    // База данных ID - ставка 
    mapping (uint64 => BetStruct) public betsDatabase;
    
    
    // события
    event createBetLog(uint32 _eventID, uint _rate, uint _value, uint betID, address _bettor  );
    


  constructor(address initAddr) public {
    //инициализируем контракт со списком событий
    eventsDatabase = EventsDatabase(0x3B4AfC80cF4F17cF42bCDa49239696F74b322a27 );//initAddr);
  }
  
  
  function createBet(uint32 _eventID, uint _rate ) public payable {
      
      EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(_eventID);
      
       // проверяем - есть ли такое событие
        if(!eventStruct.isSet){
            revert();
        }
        
        //проверяем - удовлетворяет ли присланная сумма условиям минимальной и максимальной ставки
        if( (msg.value < eventStruct.minBet)||(msg.value > eventStruct.maxBet) ){
            revert();
        }
        
        currBetID++;
        
        BetStruct memory betStruct = BetStruct({ 
               betID:currBetID,
               eventID: _eventID, 
               bettor: msg.sender,
               bookmaker: 0,
               rate: _rate,  
               bettorValue: msg.value,
               bookmakerValue: msg.value*_rate-msg.value , //поставить потом safeMath
               //bettorTakeRewardsPeriod: bettorTakeRewardsPeriod, // период, в течении которого Беттор может забрать выигрыш
               //bookmakerTakeRewardsPeriod: bookmakerTakeRewardsPeriod, // период, в течении которого Букмэйкер может забрать выигрыш
               takeRewardsPeriod: takeRewardsPeriod,
               isSet: true,
               isPaid: false
        });
        
        betsDatabase[currBetID] = betStruct;
      
        emit createBetLog( _eventID, _rate, msg.value, currBetID, msg.sender);
  } 
  
  
  function acceptBet(uint32 _betID ) public payable {

    // добавить проверку на белый список bookmaker-ов
    
    BetStruct memory betStruct = betsDatabase[_betID];
    
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert();
    }
    
    //проверяем - не приняли ли ее раньше
    if(betStruct.bookmaker!=0){
        revert();
    }
    
    //проверяем - достаточно ли средств переведено
    
    if(msg.value < betStruct.bookmakerValue){
        revert();
    }
    
    //возвращаем сдачу 
    msg.sender.transfer(msg.value - betStruct.bookmakerValue);
     
    betStruct.bookmaker =  msg.sender;
    
    betsDatabase[_betID] = betStruct;
      
  }
  
  
  function getReward(uint32 _betID ) public  {
      
    BetStruct memory betStruct = betsDatabase[_betID];
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert();
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert();
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert();
    }
    
    betStruct.isPaid = true;
    betsDatabase[_betID] = betStruct;
    
    
    // если прошло время на получение выигрыша - то эфир отправляется владельцу контракта
    if(now > (eventStruct.resultSetTime + betStruct.takeRewardsPeriod)){
        
        owner.transfer(betStruct.bettorValue + betStruct.bookmakerValue);
    } else{
        //считаем бонус владельца контракта
        uint bonus = (betStruct.bettorValue + betStruct.bookmakerValue)*eventStruct.percent/100;
        owner.transfer(bonus);
        
        if (eventStruct.result==1){
            betStruct.bettor.transfer(betStruct.bettorValue + betStruct.bookmakerValue - bonus);
        } else {
            betStruct.bookmaker.transfer(betStruct.bettorValue + betStruct.bookmakerValue - bonus);
        }
        
    }
    
      
  }
  
 function returnBet(uint32 _betID ) public  {
    BetStruct memory betStruct = betsDatabase[_betID];
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert();
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert();
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert();
    }
    
    betStruct.isPaid = true;
    betsDatabase[_betID] = betStruct;
     
    //если ставка не была принята - возвращаем деньги
    if(betStruct.bookmaker==0){
        betStruct.bettor.transfer(betStruct.bettorValue);
    }
    
     
 }

    
    
}