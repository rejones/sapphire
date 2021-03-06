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
package java.lang.ref;

import org.jikesrvm.mm.mminterface.MemoryManager;
import org.vmmagic.pragma.ReferenceFieldsVary;
import org.vmmagic.pragma.Uninterruptible;

/**
 * Implementation of java.lang.ref.SoftReference for JikesRVM.
 */
@ReferenceFieldsVary
public class SoftReference<T> extends Reference<T> {

  public SoftReference(T referent) {
    super(referent);
    MemoryManager.addSoftReference(this,referent);
  }

  public SoftReference(T referent, ReferenceQueue<T> q) {
    super(referent, q);
    MemoryManager.addSoftReference(this, referent);
  }

  @Override
  @Uninterruptible
  public boolean isSoft() {
    return true;
  }
}
