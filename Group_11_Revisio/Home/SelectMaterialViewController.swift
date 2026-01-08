//
//  SelectMaterialViewController.swift
//  MITWPU_group11 
//
//  Created by Mithil on 08/01/26.
//

import UIKit

class SelectMaterialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func doneTap(_ sender: UIButton) {
        performSegue(withIdentifier: "showGeneration", sender: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
