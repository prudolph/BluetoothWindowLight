//
//  ViewController.h
//  WindowlightControlApp
//
//  Created by Prudolph on 10/8/14.
//
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "UARTPeripheral.h"
@interface ViewController : UIViewController<CBCentralManagerDelegate,UARTPeripheralDelegate,UIPickerViewDelegate>


@property (weak,nonatomic) IBOutlet UIDatePicker *alarmPicker;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;


#pragma mark - Color Sliders

@property (weak, nonatomic) IBOutlet UISlider *redColorSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenColorSlider;

@property (weak, nonatomic) IBOutlet UISlider *blueColorSlider;

@property (weak, nonatomic) IBOutlet UIButton *setColorButton;


@property(weak,nonatomic) IBOutlet UISwitch *forceLightSwitch;

@property CGFloat  redColorValue;
@property CGFloat  greenColorValue;
@property CGFloat  blueColorValue;

-(IBAction)updateColor:(id)sender;
-(IBAction)setColor:(id)sender;

#pragma mark - incrementTime

@property (strong, nonatomic) IBOutlet UIPickerView *incrementTimePicker;

typedef enum {
    ConnectionStatusDisconnected = 0,
    ConnectionStatusScanning,
    ConnectionStatusConnected,
} ConnectionStatus;


@property (nonatomic, assign) ConnectionStatus                  connectionStatus;

@property (strong,nonatomic) NSDateFormatter *formatter;

@property (strong,nonatomic)UIColor *lightColor;


@end

