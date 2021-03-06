/*
 *  This file is part of the Jikes RVM project (http://jikesrvm.org).
 *
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License. You
 *  may obtain a copy of the License at
 *
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 *
 *  See the COPYRIGHT.txt file distributed with this work for information
 *  regarding copyright ownership.
 */
package org.mmtk.utility.alloc;

import org.vmmagic.unboxed.*;
import org.vmmagic.pragma.*;

/**
 * Callbacks from BumpPointer during a linear scan are dispatched through
 * a subclass of this object.
 */
@Uninterruptible
public abstract class LinearScan {
  /**
   * Scan an object.
   *
   * @param object The object to scan
   */
  public abstract void scan(ObjectReference object);

  public void scan(ObjectReference object, int size) { scan(object); }

  /**
   * Scan an (potentially dead) object, with a cell address and extent.
   *
   * @param object The object to scan
   * @param live Whether the object is live
   * @param cellAddress Start of the memory cell holding the object
   * @param cellExtent Length of the memory cell holding the object
   */
  public void scan(ObjectReference object, boolean live, Address cellAddress, Extent cellExtent) {
    if (live)
      scan(object);
  }

  @Inline
  public void startScanSeries() {}
  
  @Inline
  public void endScanSeries() {}
}
