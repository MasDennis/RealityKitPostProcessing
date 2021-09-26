//
//  ViewController.swift
//  RealityKitPostProcessing
//
//  Created by Dennis Ippel on 26/09/2021.
//

import UIKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!

    private var computePipelineState: MTLComputePipelineState?
    private var threadsPerThreadgroup = MTLSize()
    private var threadgroupsPerGrid = MTLSize()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)

        arView.renderCallbacks.postProcess = { [weak self] context in
            guard let self = self else { return }
            if self.computePipelineState == nil {
                self.setupComputePipeline(targetTexture: context.targetColorTexture)
            }

            guard let computePipelineState = self.computePipelineState,
                  let encoder = context.commandBuffer.makeComputeCommandEncoder()
            else {
                return
            }

            encoder.setComputePipelineState(computePipelineState)
            encoder.setTexture(context.sourceColorTexture, index: 0)
            encoder.setTexture(context.targetColorTexture, index: 1)
            encoder.dispatchThreadgroups(self.threadgroupsPerGrid, threadsPerThreadgroup: self.threadsPerThreadgroup)
            encoder.endEncoding()
        }
    }

    private func setupComputePipeline(targetTexture: MTLTexture) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary(),
              let postProcessingKernel = library.makeFunction(name: "inverseColorKernel"),
              let pipelineState = try? device.makeComputePipelineState(function: postProcessingKernel)
        else {
            assertionFailure()
            return
        }

        computePipelineState = pipelineState

        threadsPerThreadgroup = MTLSize(width: pipelineState.threadExecutionWidth,
                                        height: pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth,
                                        depth: 1)
        threadgroupsPerGrid = MTLSize(width: (targetTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                      height: (targetTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                      depth: 1)
    }
}
