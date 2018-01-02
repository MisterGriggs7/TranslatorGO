//
//  ViewController.m
//  TranslatorGO
//
//  Created by Tyler Griggs on 12/7/16.
//  Copyright © 2016 Tyler Griggs. All rights reserved.
//

#import "ViewController.h"

#import "FGTranslator.h"

@interface ViewController ()


    // outlets connected to storyboard (UI)
    @property (weak, nonatomic) IBOutlet UITextView *textView;
    @property (weak, nonatomic) IBOutlet UIImageView *imageView;
    @property (weak, nonatomic) IBOutlet UIImageView *downArrow;
    @property (weak, nonatomic) IBOutlet UIImageView *upArrow;
    @property (weak, nonatomic) IBOutlet UILabel *originalLanguage;
    @property (weak, nonatomic) IBOutlet UILabel *afterTranslationLanguage;
    @property (weak, nonatomic) IBOutlet UIButton *backToMainButton;

    @property (weak, nonatomic) IBOutlet UIButton *searchLibrary;
    @property (weak, nonatomic) IBOutlet UIButton *takeAPicture;

    @property (weak, nonatomic) IBOutlet UIImageView *translatorImage;
    @property (weak, nonatomic) IBOutlet UIImageView *goImage;

    @end

@implementation ViewController
    
- (void)viewDidLoad
    {
        [super viewDidLoad];
        
        // load the main screen view
        _textView.hidden = true;
        _imageView.hidden = true;
        _downArrow.hidden = true;
        _upArrow.hidden = true;
        _originalLanguage.hidden = true;
        _backToMainButton.hidden = true;
        _afterTranslationLanguage.hidden = true;
        
        self.textView.layer.borderWidth = 3.0f;
        self.textView.layer.borderColor = [[UIColor blackColor] CGColor];
        
        self.imageView.layer.borderWidth = 3.0f;
        self.imageView.layer.borderColor = [[UIColor blackColor] CGColor];
        
        // clean translator on each run
        [FGTranslator flushCache];
        [FGTranslator flushCredentials];
    }

// function called to translate
- (FGTranslator *)translator {

    
    FGTranslator *translator = [[FGTranslator alloc] initWithBingAzureClientId:@"thePortableTranslator" secret:@"O+gtMESZwAPFxqV+9HWHthJsA4pb0yOLQNB5vnM8ybQ="];
    
    return translator;
}
    
- (NSLocale *)currentLocale {
    NSLocale *locale = [NSLocale currentLocale];
#if TARGET_IPHONE_SIMULATOR
    return [NSLocale localeWithLocaleIdentifier:[locale localeIdentifier]];
#else
    return locale;
#endif
}
    
// if user selects "Take a Photo", open camera
- (IBAction)takeAPicture:(id)sender {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:NULL];

    }
    

// if user selects "search library", open photo library
- (IBAction)searchLibrary:(id)sender {
    
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [self presentViewController:picker animated:YES completion:NULL];
    
}

// once image is picked (via library or camera)
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // image selected or taken
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    // change image view and hide main screen buttons
    _imageView.image = chosenImage;
    _searchLibrary.hidden = true;
    _takeAPicture.hidden = true;
    
    // Create G8Tesseract object
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    
    
    // Set up the delegate to receive Tesseract's callbacks.
    tesseract.delegate = self;
    
    // set chosen image to the image to be translated
    tesseract.image = [chosenImage g8_blackAndWhite];
    
    
    // Start the recognition
    [tesseract recognize];
    
    // Retrieve the recognized text
    _textView.text = [tesseract recognizedText];
    
    [self.textView resignFirstResponder];
    
    // translate text recognized by tesseract
    [self.translator translateText:self.textView.text
                        completion:^(NSError *error, NSString *translated, NSString *sourceLanguage)
     {
         // if translation produces error, show error message
         if (error)
         {
             [self showErrorWithError:error];
        
         }
         
         // else display translated text
         else
         {

             _textView.text = translated;
             
         }
     }];
    
    // detect source language
    [self.translator detectLanguage:self.textView.text completion:^(NSError *error, NSString *detectedSource, float confidence)
     {
         // on error, show error message
         if (error)
         {
             [self showErrorWithError:error];
             
         }
         
         // else, present the detected language
         else
         {
             NSString *fromLanguage = [[self currentLocale] displayNameForKey:NSLocaleIdentifier value:detectedSource];
             
             _originalLanguage.text = fromLanguage;
         }
     }];
    
    // create new UI view
    [_translatorImage setFrame:CGRectMake(0, 20, _translatorImage.frame.size.width, _translatorImage.frame.size.height)];
    [_goImage setFrame:CGRectMake(163, 9, _goImage.frame.size.width, _goImage.frame.size.height)];
    _textView.hidden = false;
    _imageView.hidden = false;
    _downArrow.hidden = false;
    _upArrow.hidden = false;
    _originalLanguage.hidden = false;
    _afterTranslationLanguage.hidden = false;
    _backToMainButton.hidden = false;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
        
}
    

// if user selects "back" reload main creen
- (IBAction)backToMain:(id)sender {
    
    
    [_translatorImage setFrame:CGRectMake(0, 79, _translatorImage.frame.size.width, _translatorImage.frame.size.height)];
    [_goImage setFrame:CGRectMake(163, 68, _goImage.frame.size.width, _goImage.frame.size.height)];
    
    _searchLibrary.hidden = false;
    _takeAPicture.hidden = false;
    
    _textView.hidden = true;
    _imageView.hidden = true;
    _downArrow.hidden = true;
    _upArrow.hidden = true;
    _originalLanguage.hidden = true;
    _afterTranslationLanguage.hidden = true;
    _backToMainButton.hidden = true;
    
}

// error message
- (void)showErrorWithError:(NSError *)error
    {
        NSLog(@"FGTranslator failed with error: %@", error);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    @end

