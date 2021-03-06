//
//  ViewController.m
//  WindowlightControlApp
//
//  Created by Prudolph on 10/8/14.
//
//

#import "ViewController.h"
#import "NSString+hex.h"
#import "NSData+hex.h"
#import <QuartzCore/QuartzCore.h>
@interface ViewController (){
    CBCentralManager    *cm;
    UARTPeripheral      *currentPeripheral;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _connectionStatus = ConnectionStatusDisconnected;
    
    
    //Time Formatter Used through out the application
    _formatter = [[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"MMddyyHHmm"];
    
    
    
    _redColorValue  =128.0;
    _greenColorValue=128.0;
    _blueColorValue =128.0;
    _lightColor = [UIColor colorWithRed:_redColorValue green:_greenColorValue blue:_blueColorValue alpha:1];
    
    _setColorButton.layer.cornerRadius = 5;
    _setColorButton.layer.masksToBounds = YES;
    
    [_alarmPicker addTarget:self
                     action:@selector(alarmTimeSet)
           forControlEvents:UIControlEventValueChanged];
    
    
    [_forceLightSwitch addTarget:self action:@selector(forceLight:) forControlEvents:UIControlEventValueChanged];
}

-(void)viewDidAppear:(BOOL)animated{
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)scanForPeripherals{
    
    NSLog(@"Scanning for Peripherals");
    //Look for available Bluetooth LE devices
    
    //skip scanning if UART is already connected
    NSArray *connectedPeripherals = [cm retrieveConnectedPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]];
    if ([connectedPeripherals count] > 0) {
        //connect to first peripheral in array
        [self connectPeripheral:[connectedPeripherals objectAtIndex:0]];
    }
    
    else{
        
        [cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]
                                   options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
    }
}


- (void)connectPeripheral:(CBPeripheral*)peripheral{
    
    NSLog(@"Connect Peripheral");
    //Connect Bluetooth LE device
    
    //Clear off any pending connections
    [cm cancelPeripheralConnection:peripheral];
    
    //Connect
    currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    [cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    
}


- (void)disconnect{
    
    //Disconnect Bluetooth LE device
    
    _connectionStatus = ConnectionStatusDisconnected;
    
    [cm cancelPeripheralConnection:currentPeripheral.peripheral];
    
}


#pragma mark CBCentralManagerDelegate


- (void) centralManagerDidUpdateState:(CBCentralManager*)central{
    NSLog(@"centralManagerDidUpdateState");
    if (central.state == CBCentralManagerStatePoweredOn){
        NSLog(@"State is ON");
        [self scanForPeripherals];
    }
    
    else if (central.state == CBCentralManagerStatePoweredOff){
        NSLog(@"State is OFF");
        //respond to powered off
    }
    
}


- (void) centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI{
    
    NSLog(@"Did discover peripheral %@", peripheral.name);
    
    [cm stopScan];
    
    [self connectPeripheral:peripheral];
}


- (void) centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral{
    NSLog(@"didConnectPeripheral");
    if ([currentPeripheral.peripheral isEqual:peripheral]){
        
        if(peripheral.services){
            NSLog(@"Did connect to existing peripheral %@", peripheral.name);
            [currentPeripheral peripheral:peripheral didDiscoverServices:nil]; //already discovered services, DO NOT re-discover. Just pass along the peripheral.
            
        }
        
        else{
            NSLog(@"Did connect peripheral %@", peripheral.name);
            
            _notificationLabel.text = [NSString stringWithFormat:@"Did connect peripheral %@", peripheral.name];
            [currentPeripheral didConnect];
        }
    }
}


- (void) centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error{
    
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    
    //respond to disconnected
    [self peripheralDidDisconnect];
    
    if ([currentPeripheral.peripheral isEqual:peripheral])
    {
        [currentPeripheral didDisconnect];
    }
}


#pragma mark UARTPeripheralDelegate


- (void)didReadHardwareRevisionString:(NSString*)string{
    
    //Once hardware revision string is read, connection to Bluefruit is complete
    
    NSLog(@"DidReadHardwareRevisionString:: HW Revision: %@", string);
    
    
    _connectionStatus = ConnectionStatusConnected;

}


- (void)uartDidEncounterError:(NSString*)error{
    
    NSLog(@"Uart encounterd an error");
    
}


- (void)didReceiveData:(NSData*)newData{
    
    //Data incoming from UART peripheral, forward to current view controller
    
    
    //Debug
    NSString *hexString = [newData hexRepresentationWithSpaces:YES];
    
    NSString *message = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    
    
    NSLog(@"Received: %@", message);
    
    _notificationLabel.text = message;
    
    if([message isEqualToString:@"GT"]){
        [self setCurrentTime];
    }
    
}


- (void)peripheralDidDisconnect{
    
    //respond to device disconnecting
    
    //if we were in the process of scanning/connecting, dismiss alert
    
    [self uartDidEncounterError:@"Peripheral disconnected"];
    
    
    //if status was connected, then disconnect was unexpected by the user, show alert
    
    
    
    _connectionStatus = ConnectionStatusDisconnected;
    
    NSLog(@"Periphial did disconnect");
}


- (void)alertBluetoothPowerOff{
    
    //Respond to system's bluetooth disabled
    
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to connect to a device";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


- (void)alertFailedConnection{
    
    //Respond to unsuccessful connection
    
    NSString *title     = @"Unable to connect";
    NSString *message   = @"Please check power & wiring,\nthen reset your Arduino";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    
}


#pragma mark UartViewControllerDelegate / PinIOViewControllerDelegate


- (void)sendData:(NSData*)newData{
    
    //Output data to UART peripheral
    
    NSString *hexString = [newData hexRepresentationWithSpaces:YES];
    NSLog(@"Sending: %@", hexString);
    
    [currentPeripheral writeRawData:newData];
    
}



#pragma mark - UIControls


-(IBAction)setCurrentTime{
    
    NSString *currentDateTimeAsString =  [_formatter stringFromDate:[NSDate date]];
    NSString *annotatedString = [NSString stringWithFormat:@"ST:%@",currentDateTimeAsString];
    
    NSLog(@"Sending the current Time %@ to arduino",annotatedString);
    
    //Send inputField's string via UART
    NSData *data = [NSData dataWithBytes:annotatedString.UTF8String length:annotatedString.length];
    [self sendData:data];
    
}



-(void)alarmTimeSet{
    
    NSString *alarmTimeString =  [_formatter stringFromDate:_alarmPicker.date];
    
    NSString *annotatedString = [NSString stringWithFormat:@"AL:%@",alarmTimeString];
    
    NSLog(@"Set Alarm time to: %@ ", annotatedString);
    
    //Send inputField's string via UART
    NSData *data = [NSData dataWithBytes:annotatedString.UTF8String length:annotatedString.length];
    [self sendData:data];
    
    
}

#pragma mark - Update Fuctions

-(IBAction)updateColor:(id)sender{
    NSLog(@"Update Color ");
    if([sender tag] == 0){//update red
        NSLog(@"red %f",((UISlider*)sender).value);
        _redColorValue = ((UISlider*)sender).value;
    }
    else if([sender tag] == 1){//update green
        NSLog(@"Green %f",((UISlider*)sender).value);
        _greenColorValue = ((UISlider*)sender).value;
    }
    else if([sender tag] == 2){//update Blue
        NSLog(@"Blue %f",((UISlider*)sender).value);
        _blueColorValue = ((UISlider*)sender).value;
    }
    
    
    
    _lightColor = [UIColor colorWithRed:_redColorValue/255.0 green:_greenColorValue/255.0 blue:_blueColorValue/255.0 alpha:1];
    
    
    _setColorButton.backgroundColor =_lightColor;
    
    
}
-(IBAction)setColor:(id)sender{
    
    NSLog(@"Set Color %d %d %d",(int)_redColorValue,(int)_blueColorValue,(int)_greenColorValue );
    NSString *colorString = [NSString stringWithFormat:@"CL:%d,%d,%d",(int)_redColorValue,(int)_blueColorValue,(int)_greenColorValue];
    
    
    //Send inputField's string via UART
    NSData *data = [NSData dataWithBytes:colorString.UTF8String length:colorString.length];
    [self sendData:data];
}

// The number of columns of data
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 12;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%d",((row+1)*5) ];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    NSString *incrementTimeString = [NSString stringWithFormat:@"IC:%d",((row+1)*5)];
    
    //Send inputField's string via UART
    NSData *data = [NSData dataWithBytes:incrementTimeString.UTF8String length:incrementTimeString.length];
    [self sendData:data];
    
}
- (void)forceLight:(id)sender
{
    NSString *forceCommand = [NSString stringWithFormat:@"FL:%d",[sender isOn]];
    NSLog(@"%@",forceCommand );
    //Send inputField's string via UART
    NSData *data = [NSData dataWithBytes:forceCommand.UTF8String length:forceCommand.length];
    [self sendData:data];
    
}
@end
